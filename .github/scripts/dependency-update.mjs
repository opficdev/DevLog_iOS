import { readFile, writeFile } from "node:fs/promises"
import { pathToFileURL } from "node:url"

const GITHUB_API_URL = "https://api.github.com"
const OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses"
const OPENAI_MODEL = "gpt-5.6-luna"
const OPENAI_REASONING_EFFORT = "medium"
const MAX_RELEASE_NOTE_LENGTH = 16_000
const STABLE_VERSION_PATTERN = /^v?(\d+)\.(\d+)\.(\d+)$/
const DIRECT_PACKAGE_PATTERN = /\.package\(\s*url:\s*"(?<url>[^"]+)"\s*,\s*(?<requirement>\.exact\("(?<exact>[^"]+)"\)|\.upToNextMinor\(from:\s*"(?<upToNextMinor>[^"]+)"\))\s*\)/gs

export function parsePackages(manifest) {
  return [...manifest.matchAll(DIRECT_PACKAGE_PATTERN)].map(match => {
    const requirement = match.groups.exact === undefined
      ? "upToNextMinor"
      : "exact"
    const version = match.groups.exact ?? match.groups.upToNextMinor
    const requirementText = match.groups.requirement

    return {
      repository: repositoryFor(match.groups.url),
      requirement,
      version,
      requirementStart: match.index + match[0].indexOf(requirementText),
      requirementEnd: match.index + match[0].indexOf(requirementText) + requirementText.length,
    }
  })
}

export function latestCompatibleVersion(currentVersion, tags) {
  const current = versionParts(currentVersion)

  if (!current) {
    return undefined
  }

  return tags
    .map(tag => ({ tag, parts: versionParts(tag) }))
    .filter(({ parts }) => parts && parts.major === current.major)
    .filter(({ parts }) => 0 < compareVersions(parts, current))
    .sort((left, right) => compareVersions(right.parts, left.parts))
    .at(0)
    ?.tag
}

export function applyUpdates(manifest, updates) {
  const approvedByRepository = new Map(
    updates
      .filter(update => update.action === "apply")
      .map(update => [update.repository, update])
  )
  const packages = parsePackages(manifest)
  const replacements = packages
    .map(packageInfo => {
      const update = approvedByRepository.get(packageInfo.repository)

      if (!update || !isStableVersion(update.candidateVersion)) {
        return undefined
      }

      return {
        ...packageInfo,
        value: packageInfo.requirement === "exact"
          ? `.exact("${update.candidateVersion}")`
          : `.upToNextMinor(from: "${update.candidateVersion}")`,
      }
    })
    .filter(Boolean)
    .sort((left, right) => right.requirementStart - left.requirementStart)

  return replacements.reduce(
    (result, replacement) => result.slice(0, replacement.requirementStart)
      + replacement.value
      + result.slice(replacement.requirementEnd),
    manifest
  )
}

export async function decideCandidates({
  packages,
  apiKey,
  fetcher = fetch,
}) {
  const candidates = packages.filter(packageInfo => packageInfo.candidateVersion)
  const automaticCandidates = candidates.filter(
    packageInfo => packageInfo.releaseNotes?.status === "available"
  )
  const manualPackages = candidates
    .filter(packageInfo => packageInfo.releaseNotes?.status !== "available")
    .map(packageInfo => manualReview(packageInfo, packageInfo.manualReviewReason))

  if (!apiKey) {
    return {
      packages: [
        ...automaticCandidates.map(packageInfo => manualReview(
          packageInfo,
          "OpenAI API key가 없어 수동 확인 필요"
        )),
        ...manualPackages,
      ],
    }
  }

  if (automaticCandidates.length === 0) {
    return { packages: manualPackages }
  }

  try {
    const response = await fetcher(OPENAI_RESPONSES_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(openAiRequest(automaticCandidates)),
    })

    if (!response.ok) {
      return {
        packages: [
          ...automaticCandidates.map(packageInfo => manualReview(
            packageInfo,
            `OpenAI 판정 요청 실패: HTTP ${response.status}`
          )),
          ...manualPackages,
        ],
      }
    }

    const value = await response.json()
    const parsed = JSON.parse(openAiTextFor(value))

    return {
      packages: [
        ...automaticCandidates.map(packageInfo => decisionFor(packageInfo, parsed.packages)),
        ...manualPackages,
      ],
    }
  } catch {
    return {
      packages: [
        ...automaticCandidates.map(packageInfo => manualReview(
          packageInfo,
          "OpenAI 판정 응답을 처리하지 못했으므로 수동 확인 필요"
        )),
        ...manualPackages,
      ],
    }
  }
}

export function renderPrBodySection({ runId, packages, now = new Date() }) {
  const applied = packages.filter(packageInfo => packageInfo.action === "apply")
  const manual = packages.filter(packageInfo => packageInfo.action === "manual_review")
  const date = now.toISOString().replace("T", " ").replace(/\.\d{3}Z$/, " UTC")
  const lines = [
    `<!-- dependency-update:${runId} -->`,
    `### ${date} 의존성 갱신 실행`,
    "",
  ]

  if (applied.length !== 0) {
    lines.push("#### 반영 후보", "")
    lines.push("| package | 이전 | 이후 | 근거 |")
    lines.push("| --- | --- | --- | --- |")
    lines.push(...applied.map(packageInfo => [
      packageInfo.repository,
      packageInfo.currentVersion,
      packageInfo.candidateVersion,
      packageInfo.evidence || "변경 이력 확인",
    ].map(escapeTable).join(" | ").replace(/^/, "| ").concat(" |")))
    lines.push("")
  }

  if (manual.length !== 0) {
    lines.push("#### 수동 확인 필요", "")
    lines.push(...manual.map(packageInfo => [
      `- ${packageInfo.repository}`,
      `${packageInfo.currentVersion} → ${packageInfo.candidateVersion}`,
      packageInfo.manualReviewReason,
      packageInfo.releaseNotes?.url,
    ].filter(Boolean).join(" — ")))
    lines.push("")
  }

  return `${lines.join("\n").trimEnd()}\n`
}

export async function discoverCandidates({
  manifest,
  githubToken,
  fetcher = fetch,
}) {
  const packages = parsePackages(manifest)

  return Promise.all(packages.map(async packageInfo => {
    const current = versionParts(packageInfo.version)

    if (!current) {
      return {
        ...publicPackageInfo(packageInfo),
        candidateVersion: undefined,
        manualReviewReason: "현재 requirement가 정식 버전이 아님",
      }
    }

    try {
      const tags = await tagsFor(packageInfo.repository, githubToken, fetcher)
      const candidateVersion = latestCompatibleVersion(packageInfo.version, tags)

      if (!candidateVersion) {
        return {
          ...publicPackageInfo(packageInfo),
          candidateVersion: undefined,
          manualReviewReason: undefined,
        }
      }

      const releaseNotes = await releaseNotesFor(
        packageInfo.repository,
        candidateVersion,
        githubToken,
        fetcher
      )

      return {
        ...publicPackageInfo(packageInfo),
        candidateVersion,
        releaseNotes,
        manualReviewReason: releaseNotes.status === "available"
          ? undefined
          : "변경 이력을 확인하지 못했으므로 수동 확인 필요",
      }
    } catch (error) {
      return {
        ...publicPackageInfo(packageInfo),
        candidateVersion: undefined,
        manualReviewReason: error instanceof Error
          ? error.message
          : "후보 버전 조회 실패",
      }
    }
  }))
}

async function tagsFor(repository, githubToken, fetcher) {
  const value = await githubJson(
    `/repos/${repository}/tags?per_page=100`,
    githubToken,
    fetcher
  )

  if (!Array.isArray(value)) {
    throw new Error("태그 응답 형식 오류")
  }

  return value
    .map(tag => tag?.name)
    .filter(isStableVersion)
}

async function releaseNotesFor(repository, version, githubToken, fetcher) {
  const url = `${GITHUB_API_URL}/repos/${repository}/releases/tags/${encodeURIComponent(version)}`
  const response = await fetcher(url, {
    headers: githubHeaders(githubToken),
  })

  if (response.status === 404) {
    return {
      status: "missing",
      url: `https://github.com/${repository}/releases/tag/${version}`,
      body: undefined,
      truncated: false,
    }
  }

  if (!response.ok) {
    throw new Error(`변경 이력 조회 실패: HTTP ${response.status}`)
  }

  const value = await response.json()
  const body = typeof value.body === "string" ? value.body.trim() : ""

  if (!body) {
    return {
      status: "missing",
      url: typeof value.html_url === "string"
        ? value.html_url
        : `https://github.com/${repository}/releases/tag/${version}`,
      body: undefined,
      truncated: false,
    }
  }

  return {
    status: "available",
    url: typeof value.html_url === "string"
      ? value.html_url
      : `https://github.com/${repository}/releases/tag/${version}`,
    body: body.slice(0, MAX_RELEASE_NOTE_LENGTH),
    truncated: MAX_RELEASE_NOTE_LENGTH < body.length,
  }
}

async function githubJson(path, githubToken, fetcher) {
  const response = await fetcher(`${GITHUB_API_URL}${path}`, {
    headers: githubHeaders(githubToken),
  })

  if (!response.ok) {
    throw new Error(`GitHub API 조회 실패: HTTP ${response.status}`)
  }

  return response.json()
}

function githubHeaders(githubToken) {
  return {
    Accept: "application/vnd.github+json",
    ...(githubToken ? { Authorization: `Bearer ${githubToken}` } : {}),
  }
}

function publicPackageInfo(packageInfo) {
  return {
    repository: packageInfo.repository,
    requirement: packageInfo.requirement,
    currentVersion: packageInfo.version,
  }
}

function openAiRequest(packages) {
  return {
    model: OPENAI_MODEL,
    reasoning: {
      effort: OPENAI_REASONING_EFFORT,
    },
    input: [
      {
        role: "developer",
        content: [
          "제공된 release note만 근거로 package별 반영 여부를 판단.",
          "breaking change, migration, deprecation, 보안 또는 호환성 불확실성이 있으면 manual_review 선택.",
          "확인 가능한 버그 수정·호환성 변경뿐이면 apply 선택.",
          "후보가 현재 프로젝트에 불필요하다고 근거로 확인되면 skip 선택.",
          "추정, 외부 API, 제공되지 않은 변경을 근거로 사용 금지.",
          "evidence와 manualReviewReason은 한국어 작성.",
        ].join("\n"),
      },
      {
        role: "user",
        content: JSON.stringify(packages.map(packageInfo => ({
          repository: packageInfo.repository,
          currentVersion: packageInfo.currentVersion,
          candidateVersion: packageInfo.candidateVersion,
          releaseNoteUrl: packageInfo.releaseNotes.url,
          releaseNote: packageInfo.releaseNotes.body,
          releaseNoteTruncated: packageInfo.releaseNotes.truncated,
        }))),
      },
    ],
    text: {
      format: {
        type: "json_schema",
        name: "dependency_update_decisions",
        strict: true,
        schema: decisionSchema(),
      },
    },
  }
}

function decisionSchema() {
  return {
    type: "object",
    additionalProperties: false,
    properties: {
      packages: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          properties: {
            repository: { type: "string" },
            action: {
              type: "string",
              enum: ["apply", "manual_review", "skip"],
            },
            evidence: { type: "string" },
            manualReviewReason: { type: ["string", "null"] },
          },
          required: [
            "repository",
            "action",
            "evidence",
            "manualReviewReason",
          ],
        },
      },
    },
    required: ["packages"],
  }
}

function openAiTextFor(value) {
  if (typeof value.output_text === "string" && value.output_text.trim()) {
    return value.output_text
  }

  const text = value.output
    ?.flatMap(item => item.content ?? [])
    .map(content => content.text ?? "")
    .join("")

  if (!text?.trim()) {
    throw new Error("OpenAI 응답 text 없음")
  }

  return text
}

function decisionFor(packageInfo, decisions) {
  const decision = decisions?.find(value => value?.repository === packageInfo.repository)

  if (!["apply", "manual_review", "skip"].includes(decision?.action)) {
    return manualReview(packageInfo, "OpenAI 판정 형식을 확인하지 못했으므로 수동 확인 필요")
  }

  return {
    ...packageInfo,
    action: decision.action,
    evidence: typeof decision.evidence === "string" ? decision.evidence : "",
    manualReviewReason: decision.action === "manual_review"
      ? decision.manualReviewReason || "변경 이력 수동 확인 필요"
      : null,
  }
}

function manualReview(packageInfo, reason) {
  return {
    ...packageInfo,
    action: "manual_review",
    evidence: "",
    manualReviewReason: reason || "변경 이력 수동 확인 필요",
  }
}

function escapeTable(value) {
  return String(value).replaceAll("|", "\\|").replaceAll("\n", " ")
}

function repositoryFor(url) {
  const match = url.match(/^https:\/\/github\.com\/(?<owner>[^/]+)\/(?<name>[^/]+?)(?:\.git)?$/)

  if (!match) {
    throw new Error(`GitHub repository URL이 아님: ${url}`)
  }

  return `${match.groups.owner}/${match.groups.name}`
}

function isStableVersion(value) {
  return versionParts(value) !== undefined
}

function versionParts(value) {
  const match = value.match(STABLE_VERSION_PATTERN)

  if (!match) {
    return undefined
  }

  return {
    major: Number(match[1]),
    minor: Number(match[2]),
    patch: Number(match[3]),
  }
}

function compareVersions(left, right) {
  if (left.major !== right.major) {
    return left.major - right.major
  }

  if (left.minor !== right.minor) {
    return left.minor - right.minor
  }

  return left.patch - right.patch
}

async function main() {
  const [command, ...argumentsList] = process.argv.slice(2)
  const manifestPath = option(argumentsList, "--manifest")
  const outputPath = option(argumentsList, "--output")

  if (!manifestPath || !outputPath) {
    throw new Error("--manifest와 --output이 필요")
  }

  const manifest = await readFile(manifestPath, "utf8")

  if (command === "discover") {
    const packages = await discoverCandidates({
      manifest,
      githubToken: process.env.GITHUB_TOKEN,
    })
    await writeJson(outputPath, { packages })
    return
  }

  if (command === "decide") {
    const discoveryPath = option(argumentsList, "--discovery")

    if (!discoveryPath) {
      throw new Error("decide에는 --discovery가 필요")
    }

    const discovery = await readJson(discoveryPath)
    const decisions = await decideCandidates({
      packages: discovery.packages ?? discovery,
      apiKey: process.env.OPENAI_API_KEY,
    })
    await writeJson(outputPath, decisions)
    return
  }

  if (command === "render-pr-body") {
    const decisionsPath = option(argumentsList, "--decisions")
    const runId = option(argumentsList, "--run-id")

    if (!decisionsPath || !runId) {
      throw new Error("render-pr-body에는 --decisions와 --run-id가 필요")
    }

    const decisions = await readJson(decisionsPath)
    await writeFile(outputPath, renderPrBodySection({
      runId,
      packages: decisions.packages ?? decisions,
    }))
    return
  }

  if (command === "apply") {
    const updatesPath = option(argumentsList, "--updates")

    if (!updatesPath) {
      throw new Error("apply에는 --updates가 필요")
    }

    const updates = await readJson(updatesPath)
    const nextManifest = applyUpdates(manifest, updates.packages ?? updates)
    await writeFile(outputPath, nextManifest)
    return
  }

  throw new Error(`지원하지 않는 명령: ${command}`)
}

function option(argumentsList, name) {
  const index = argumentsList.indexOf(name)
  return 0 <= index ? argumentsList[index + 1] : undefined
}

async function readJson(path) {
  return JSON.parse(await readFile(path, "utf8"))
}

async function writeJson(path, value) {
  await writeFile(path, `${JSON.stringify(value, null, 2)}\n`)
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch(error => {
    console.error(error instanceof Error ? error.message : error)
    process.exitCode = 1
  })
}

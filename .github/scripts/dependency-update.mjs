import { readFile, writeFile } from "node:fs/promises"
import { pathToFileURL } from "node:url"

const GITHUB_API_URL = "https://api.github.com"
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

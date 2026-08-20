import assert from "node:assert/strict"
import test from "node:test"

import {
    applyUpdates,
    decideCandidates,
    latestCompatibleVersion,
    parsePackages,
    renderPrBodySection,
} from "./dependency-update.mjs"

const manifest = `
let project = Project(
    packages: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk",
            .exact("11.15.0")
        ),
        .package(
            url: "https://github.com/opficdev/Nexa",
            .upToNextMinor(from: "1.1.1")
        ),
    ],
    targets: [
        .target(
            dependencies: [
                .package(product: "FirebaseCore"),
            ]
        ),
    ]
)
`

test("parses direct package requirements without product dependencies", () => {
    assert.deepEqual(
        parsePackages(manifest).map(({ repository, requirement, version }) => ({
            repository,
            requirement,
            version,
        })),
        [
            {
                repository: "firebase/firebase-ios-sdk",
                requirement: "exact",
                version: "11.15.0",
            },
            {
                repository: "opficdev/Nexa",
                requirement: "upToNextMinor",
                version: "1.1.1",
            },
        ]
    )
})

test("selects the newest stable version in the current major version", () => {
    assert.equal(
        latestCompatibleVersion("11.15.0", [
            "12.0.0",
            "11.16.0-beta.1",
            "11.15.1",
            "11.16.0",
            "11.14.9",
        ]),
        "11.16.0"
    )
})

test("preserves requirement forms while applying only approved updates", () => {
    assert.equal(
        applyUpdates(manifest, [
            {
                repository: "firebase/firebase-ios-sdk",
                action: "apply",
                candidateVersion: "11.16.0",
            },
            {
                repository: "opficdev/Nexa",
                action: "manual_review",
                candidateVersion: "1.2.0",
            },
        ]),
        manifest.replace('.exact("11.15.0")', '.exact("11.16.0")')
    )
})

test("uses gpt-5.6-luna medium reasoning with a strict decision schema", async () => {
    const requests = []
    const decisions = await decideCandidates({
        packages: [candidatePackage()],
        apiKey: "test-key",
        fetcher: async (url, options) => {
            requests.push({ url, options })

            return jsonResponse({
                output_text: JSON.stringify({
                    packages: [
                        {
                            repository: "opficdev/Nexa",
                            action: "apply",
                            evidence: "버그 수정과 호환성 변경만 확인",
                            manualReviewReason: null,
                        },
                    ],
                }),
            })
        },
    })

    assert.equal(decisions.packages[0]?.action, "apply")

    const body = JSON.parse(requests[0]?.options.body)
    assert.equal(requests[0]?.url, "https://api.openai.com/v1/responses")
    assert.equal(body.model, "gpt-5.6-luna")
    assert.equal(body.reasoning.effort, "medium")
    assert.equal(body.text.format.type, "json_schema")
    assert.equal(body.text.format.strict, true)
})

test("records OpenAI request failures as manual review without raw error output", async () => {
    const decisions = await decideCandidates({
        packages: [candidatePackage()],
        apiKey: "test-key",
        fetcher: async () => ({
            ok: false,
            status: 429,
            text: async () => "api response must not be retained",
        }),
    })

    assert.equal(decisions.packages[0]?.action, "manual_review")
    assert.match(decisions.packages[0]?.manualReviewReason, /HTTP 429/)
    assert.doesNotMatch(
        decisions.packages[0]?.manualReviewReason,
        /api response must not be retained/
    )
})

test("renders an append-only PR section for approved and manual-review results", () => {
    const section = renderPrBodySection({
        runId: "123",
        packages: [
            {
                ...candidatePackage(),
                action: "apply",
                evidence: "버그 수정 확인",
                manualReviewReason: null,
            },
            {
                ...candidatePackage(),
                repository: "apple/swift-collections",
                action: "manual_review",
                evidence: "",
                manualReviewReason: "변경 이력 확인 필요",
            },
        ],
        now: new Date("2026-08-20T00:00:00Z"),
    })

    assert.match(section, /<!-- dependency-update:123 -->/)
    assert.match(section, /opficdev\/Nexa.*1\.1\.1.*1\.2\.0/)
    assert.match(section, /변경 이력 확인 필요/)
})

function candidatePackage() {
    return {
        repository: "opficdev/Nexa",
        requirement: "upToNextMinor",
        currentVersion: "1.1.1",
        candidateVersion: "1.2.0",
        releaseNotes: {
            status: "available",
            url: "https://github.com/opficdev/Nexa/releases/tag/1.2.0",
            body: "Bug fixes",
            truncated: false,
        },
        manualReviewReason: null,
    }
}

function jsonResponse(value) {
    return {
        ok: true,
        json: async () => value,
    }
}

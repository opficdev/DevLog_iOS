import assert from "node:assert/strict"
import test from "node:test"

import {
    applyUpdates,
    latestCompatibleVersion,
    parsePackages,
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

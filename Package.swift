// swift-tools-version: 6.0
// SPDX-License-Identifier: AGPL-3.0-only
// SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

import PackageDescription

let package = Package(
    name: "MyTimeBuddy",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "MyTimeBuddy", targets: ["MyTimeBuddy"])
    ],
    targets: [
        .target(
            name: "MyTimeBuddy",
            path: "MyTimeBuddy/Models"
        ),
        .testTarget(
            name: "MyTimeBuddyTests",
            dependencies: ["MyTimeBuddy"],
            path: "MyTimeBuddyTests"
        )
    ]
)

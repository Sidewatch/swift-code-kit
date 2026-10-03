// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swift-code-kit",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CodeLanguage", targets: ["CodeLanguage"]),
        .library(name: "CodeHighlighting", targets: ["CodeHighlighting"]),
    ],
    dependencies: [
        .package(path: "../swift-foundation-extensions"),
        .package(path: "../swift-appkit-ui"),
        .package(path: "../swift-data-converter"),
        .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter.git", from: "0.8.0"),
        // Every grammar, in one dynamic library shared by the app and its Quick Look extension.
        .package(path: "Grammars/tree-sitter-grammars"),
    ],
    targets: [
        .target(name: "CodeLanguage", swiftSettings: [.swiftLanguageMode(.v6)]),
        .target(
            name: "CodeHighlighting",
            dependencies: [
                "CodeLanguage",
                .product(name: "FoundationExtensions", package: "swift-foundation-extensions"),
                .product(name: "AppKitViews", package: "swift-appkit-ui"),
                .product(name: "DataConverter", package: "swift-data-converter"),
                .product(name: "SwiftTreeSitter", package: "SwiftTreeSitter"),
                .product(name: "TreeSitterGrammars", package: "tree-sitter-grammars"),
            ],
            resources: [.copy("Builtins"), .process("Localizable.xcstrings")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // Dev tool: each showcase's colours as roles, for scripts/highlight-oracle in the app.
        .executableTarget(
            name: "HighlightRoles", dependencies: ["CodeHighlighting", "CodeLanguage"],
            swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "CodeLanguageTests", dependencies: ["CodeLanguage"]),
        .testTarget(
            name: "CodeHighlightingTests",
            dependencies: [
                "CodeHighlighting",
                .product(name: "SwiftTreeSitter", package: "SwiftTreeSitter"),
            ],
            exclude: ["Fixtures"],  // read by #filePath, not bundled
            resources: [.copy("Resources/jsfx.json")]
        ),
    ]
)

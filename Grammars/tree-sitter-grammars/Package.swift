// swift-tools-version: 6.2
//
// Every vendored tree-sitter grammar in ONE dynamic library. The app and its Quick Look extension
// both highlight with these grammars; linked statically, each binary carried its own ~43 MB copy
// of the parse tables. As one dylib embedded once in the app's Frameworks folder, both load the
// same file. Pure C: no Swift or Objective-C type is duplicated across the two images.
import PackageDescription

let package = Package(
    name: "tree-sitter-grammars",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TreeSitterGrammars", type: .dynamic, targets: ["TreeSitterGrammars"]),
    ],
    dependencies: [
        .package(path: "../tree-sitter-bash"),
        .package(path: "../tree-sitter-c"),
        .package(path: "../tree-sitter-cpp"),
        .package(path: "../tree-sitter-csharp"),
        .package(path: "../tree-sitter-css"),
        .package(path: "../tree-sitter-dart"),
        .package(path: "../tree-sitter-dockerfile"),
        .package(path: "../tree-sitter-go"),
        .package(path: "../tree-sitter-html"),
        .package(path: "../tree-sitter-java"),
        .package(path: "../tree-sitter-javascript"),
        .package(path: "../tree-sitter-json"),
        .package(path: "../tree-sitter-kotlin"),
        .package(path: "../tree-sitter-lua"),
        .package(path: "../tree-sitter-markdown"),
        .package(path: "../tree-sitter-php"),
        .package(path: "../tree-sitter-python"),
        .package(path: "../tree-sitter-ruby"),
        .package(path: "../tree-sitter-rust"),
        .package(path: "../tree-sitter-scala"),
        .package(path: "../tree-sitter-sql"),
        .package(path: "../tree-sitter-swift"),
        .package(path: "../tree-sitter-toml"),
        .package(path: "../tree-sitter-typescript"),
        .package(path: "../tree-sitter-xml"),
        .package(path: "../tree-sitter-yaml"),
    ],
    targets: [
        .target(
            name: "TreeSitterGrammars",
            dependencies: [
                .product(name: "TreeSitterBash", package: "tree-sitter-bash"),
                .product(name: "TreeSitterC", package: "tree-sitter-c"),
                .product(name: "TreeSitterCPP", package: "tree-sitter-cpp"),
                .product(name: "TreeSitterCSharp", package: "tree-sitter-csharp"),
                .product(name: "TreeSitterCSS", package: "tree-sitter-css"),
                .product(name: "TreeSitterDart", package: "tree-sitter-dart"),
                .product(name: "TreeSitterDockerfile", package: "tree-sitter-dockerfile"),
                .product(name: "TreeSitterGo", package: "tree-sitter-go"),
                .product(name: "TreeSitterHTML", package: "tree-sitter-html"),
                .product(name: "TreeSitterJava", package: "tree-sitter-java"),
                .product(name: "TreeSitterJavaScript", package: "tree-sitter-javascript"),
                .product(name: "TreeSitterJSON", package: "tree-sitter-json"),
                .product(name: "TreeSitterKotlin", package: "tree-sitter-kotlin"),
                .product(name: "TreeSitterLua", package: "tree-sitter-lua"),
                .product(name: "TreeSitterMarkdown", package: "tree-sitter-markdown"),
                .product(name: "TreeSitterPHP", package: "tree-sitter-php"),
                .product(name: "TreeSitterPython", package: "tree-sitter-python"),
                .product(name: "TreeSitterRuby", package: "tree-sitter-ruby"),
                .product(name: "TreeSitterRust", package: "tree-sitter-rust"),
                .product(name: "TreeSitterScala", package: "tree-sitter-scala"),
                .product(name: "TreeSitterSQL", package: "tree-sitter-sql"),
                .product(name: "TreeSitterSwift", package: "tree-sitter-swift"),
                .product(name: "TreeSitterTOML", package: "tree-sitter-toml"),
                .product(name: "TreeSitterTypeScript", package: "tree-sitter-typescript"),
                .product(name: "TreeSitterXML", package: "tree-sitter-xml"),
                .product(name: "TreeSitterYAML", package: "tree-sitter-yaml"),
            ]
        ),
    ]
)

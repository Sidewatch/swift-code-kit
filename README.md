# Swift Code Kit

Source code, understood: which language a file is, and syntax highlighting for it — tree-sitter for 26 grammars, rule tables for the rest.

## Modules

Each module is its own library product: depend on the package, then only on the products you use.

| Module | What it is |
|---|---|
| [`CodeLanguage`](Docs/Modules/CodeLanguage.md) | Filename → language detection across a 217-language catalog, with display metadata and a highlighting family for fallback. |
| [`CodeHighlighting`](Docs/Modules/CodeHighlighting.md) | Syntax highlighting for `NSTextStorage`: tree-sitter for the vendored grammars under `Grammars/`, rule tables for everything else. |

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/Sidewatch/swift-code-kit.git", from: "0.1.0")
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "CodeLanguage", package: "swift-code-kit"),
    ]),
]
```

## Requirements

- macOS 14+
- Swift 6.2+ (Swift 6 language mode)

## History

The modules were separate packages until 27 September 2026 (`swift-code-language`, `swift-code-highlighting`); their commits are kept here, so `git log --follow` traces any file back through them.

## Licence

MIT — see [LICENSE](LICENSE).

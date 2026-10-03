# Swift Code Kit

Source code, understood: which language a file is, and syntax highlighting for it — tree-sitter for 26 grammars, rule tables for the rest.

## Modules

Each module is its own library product: depend on the package, then only on the products you use.

| Module | What it is |
|---|---|
| [`CodeLanguage`](Docs/Modules/CodeLanguage.md) | Filename → language detection across a 217-language catalog, with display metadata and a highlighting family for fallback. |
| [`CodeHighlighting`](Docs/Modules/CodeHighlighting.md) | Syntax highlighting for `NSTextStorage`: tree-sitter for the vendored grammars under `Grammars/` (linked as one dynamic library, `libTreeSitterGrammars.dylib`, so an app and its extensions can share a single copy), rule tables for everything else. |

## Requirements

- macOS 14+
- Swift 6.2+ (Swift 6 language mode)

## Installation

### Swift Package Manager

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

## Usage

### CodeLanguage

```swift
import CodeLanguage

// Detect from a URL (uses the last path component only — never reads the file).
let lang = Language.detect(for: URL(fileURLWithPath: "/repo/Sources/main.swift"))
// .swift

// Per-language metadata.
lang.displayName        // "Swift"
lang.lineCommentToken   // "//"
lang.blockComment       // BlockComment(open: "/*", close: "*/")
lang.family             // .cLike

// Detect from a bare filename.
Language.detect(filename: "Makefile")          // .makefile   (exact filename)
Language.detect(filename: "tsconfig.json")     // .jsonc      (filename beats .json)
Language.detect(filename: "Dockerfile.prod")   // .dockerfile (prefix rule)
Language.detect(filename: ".env.local")        // .dotenv     (prefix rule)
Language.detect(filename: ".envrc")            // .bash       (direnv is a bash script)
Language.detect(filename: "welcome.blade.php") // .blade      (compound beats .php)
Language.detect(filename: "mystery.zzq")       // .plainText  (unrecognized)

// Matching is case-insensitive throughout.
Language.detect(filename: "README.MD")         // .markdown

// Drive a fallback highlighter from the family.
switch Language.detect(filename: "deploy.zsh").family {
case .shellLike: break  // '#' comments, $VAR interpolation, …
case .cLike:     break  // '//' + '/* */', braces, C-style keywords, …
default:         break
}
```

### CodeHighlighting

```swift
import CodeHighlighting
import CodeLanguage

// Your theme: a color per token role.
struct MyColors: TokenColorProviding {
    func color(for kind: TokenKind) -> NSColor {
        switch kind {
        case .comment:   return .systemGreen
        case .string:    return .systemRed
        case .keyword:   return .systemPurple
        case .type:      return .systemTeal
        case .number:    return .systemOrange
        case .function:  return .systemBlue
        case .attribute: return .systemTeal
        case .variable:  return .labelColor
        case .property:  return .systemIndigo
        }
    }
    var foreground: NSColor { .textColor }
}

// The tree-sitter engine reads the process-wide provider; set it once at launch.
HighlightTheme.colors = MyColors()

// Prefer tree-sitter when a grammar is bundled; fall back to regex.
let language = CodeLanguage.Language.detect(for: fileURL)
let highlighter: CodeHighlighter = TreeSitterHighlighter(language: language)
    ?? SyntaxHighlighter(language: language, colors: MyColors())
highlighter.highlight(textView.textStorage!, in: editedRange)   // main thread
```

Each module's full guide is `Docs/Modules/<Module>.md`.

## Notes

The modules were separate packages until 27 September 2026 (`swift-code-language`, `swift-code-highlighting`); their commits are kept here, so `git log --follow` traces any file back through them.

## For agents

Read `CONTRIBUTING.md` first: the folder layout and the PR rules. `swift test` is the whole
check, and a new test must fail before the change it covers. `CLAUDE.md` / `AGENTS.md` carry a
module map.

## License

MIT — see [LICENSE](LICENSE).

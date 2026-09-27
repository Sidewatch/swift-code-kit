# Swift Code Language

Filename → programming-language detection for a 217-case catalog of source, markup, and config languages, with per-language display metadata and a coarse `HighlightFamily` for fallback syntax highlighting. Pure Swift, Foundation only, zero dependencies — and it never reads file contents, so detection is instant and safe on any path.

## Features

- 🗂 **217-case language catalog** — `Language` is a `String`-backed, `CaseIterable`, `Sendable` enum covering source, markup, data, and config languages, with a `.plainText` fallback for everything else
- 🔍 **Filename-only detection** — `Language.detect(for: URL)` / `Language.detect(filename:)` resolve a language from the name alone; case-insensitive, never touches disk
- 🥇 **Layered precedence rules** — exact filenames (`Makefile`, `tsconfig.json` → JSONC, `CMakeLists.txt`) beat prefix rules (`Dockerfile.*`, `.env.*`), which beat compound extensions (`.blade.php`, `.html.erb`), which beat the plain extension map
- ⚔️ **Curated collision winners** — contested extensions resolve deterministically: `.m` → Objective-C (not MATLAB), `.v` → Verilog (not V), `.pl` → Perl (not Prolog), `.ts` → TypeScript, `.do` → Stata, `.h` → C
- 🏷 **Display metadata** — `displayName` (`"C++"`, `"Objective-C"`), `lineCommentToken` (`"//"`, `"#"`, `"--"`), and `blockComment` (a `BlockComment` open/close pair) per language
- 🎨 **`HighlightFamily` fallback** — `language.family` buckets every language into a coarse syntax family (`cLike`, `rubyLike`, `lispLike`, `mlLike`, `shellLike`, `markup`, `config`, `sql`, `tex`, `data`, `plain`) so a highlighter without a dedicated grammar can pick a reasonable rule set
- 🪶 **Zero dependencies** — Foundation only; all tables are static Swift, no I/O, no regex engines
- 🧪 **Fully tested** — precedence, dotfiles, contested extensions, case-insensitivity, and degenerate names (`""`, `"."`, `"trailing."`) are pinned by an edge-case suite

## Requirements

- Swift 6.2+ (Swift 6 language mode)
- macOS 14+ (Foundation only; other Apple platforms at SwiftPM's default minimums)

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Sidewatch/swift-code-language.git", from: "0.1.0")
]
```

Then add `"CodeLanguage"` to your target's dependencies.

## Usage

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

## Notes

- Detection is **filename-only by design** — there is no shebang or content sniffing, so results are deterministic and free of I/O.
- `HighlightFamily` is deliberately **coarse**: many languages only approximately fit their family. It exists to pick a *reasonable* fallback rule set, not to classify precisely.
- The `Language` catalog and detection tables are **generated** from a curated catalog — edit the generator, not the Swift files.

## For agents

Read `CONTRIBUTING.md` first: the folder layout and the PR rules. `swift test` is the whole
check, and a new test must fail before the change it covers. `CLAUDE.md` / `AGENTS.md` carry a
module map.

## License

MIT

# Swift Code Language

Filename → programming-language detection for a 217-case catalog of source, markup, and config languages, with per-language display metadata and a coarse `HighlightFamily` for fallback syntax highlighting. Pure Swift, Foundation only, zero dependencies — and it never reads file contents, so detection is instant and safe on any path.

- Module `CodeLanguage` in `Sources/CodeLanguage`; tests in `Tests`; `swift test` is the whole check.
- Swift 6 language mode, tools 6.2, macOS 14+, no dependencies unless the README says so.
- Part of the Sidewatch package family; every package follows the same layout and PR rules.

## Module map

- `Enums/` — enums with no behaviour beyond their cases and labels: HighlightFamily, Language
- `Extensions/` — extensions on Foundation / stdlib / other types: Language+Detection, Language+Metadata, Language+Names (`names(for:)`: every extension and exact filename the detector answers a language from, for a caller that needs to enumerate them — a corpus check asking "is there a fixture for every name we claim?")
- `Models/` — value types — the shape of a thing, nothing else: BlockComment

## Rules

@CONTRIBUTING.md

- **Auditing? Read `AUDIT.md` first** — what the last full audit checked and fixed, and the known non-issues to skip; extend it, do not redo it.

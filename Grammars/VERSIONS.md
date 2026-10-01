# Vendored grammar versions

Which upstream version each grammar under `Grammars/` is, checked on 2 October 2026 by comparing the vendored
`src/grammar.json` with upstream's at every release tag and at HEAD. Re-check any time with
`scripts/check_grammar_versions.py` (exits 1 when a grammar is behind its latest release).

"Release" means the vendored grammar is byte-identical to that tag. "Upstream main" means it matches upstream's
head, which is ahead of the last tag (some repositories rarely tag).

| Grammar | Upstream | Vendored | Latest release | Status |
|---|---|---|---|---|
| bash | tree-sitter/tree-sitter-bash | v0.25.1 | v0.25.1 | current (= main) |
| c | tree-sitter/tree-sitter-c | v0.24.2 | v0.24.2 | current (= main) |
| cpp | tree-sitter/tree-sitter-cpp | upstream main | v0.23.4 | ahead of the release |
| csharp | tree-sitter/tree-sitter-c-sharp | upstream main | v0.23.5 | ahead of the release |
| css | tree-sitter/tree-sitter-css | v0.25.0 | v0.25.0 | current (= main) |
| dart | UserNobody14/tree-sitter-dart | upstream main | none tagged | current |
| dockerfile | camdencheek/tree-sitter-dockerfile | upstream main | v0.2.0 | ahead of the release |
| go | tree-sitter/tree-sitter-go | v0.25.0 | v0.25.0 | current (= main) |
| html | tree-sitter/tree-sitter-html | v0.23.2 | v0.23.2 | current (= main) |
| java | tree-sitter/tree-sitter-java | v0.23.5 | v0.23.5 | current (= main) |
| javascript | tree-sitter/tree-sitter-javascript | v0.25.0 | v0.25.0 | current (= main) |
| json | tree-sitter/tree-sitter-json | upstream main 254c42a6, generated here with CLI 0.24.4 | v0.24.8 | current; main fixes `1E+9` (signed exponents) — a real JSON parse error, unreleased since 17 Aug 2026 |
| kotlin | fwcd/tree-sitter-kotlin | upstream main 1852ea17 (1 Aug 2026) | 0.3.8 | current; updated 2 Oct 2026 from 68f564d4 |
| lua | tree-sitter-grammars/tree-sitter-lua | v0.5.0 | v0.5.0 | current (= main) |
| markdown (block + inline) | tree-sitter-grammars/tree-sitter-markdown | v0.5.3 | v0.5.3 | current (= main) |
| php | tree-sitter/tree-sitter-php | v0.25.0 | v0.25.0 | current (= main) |
| python | tree-sitter/tree-sitter-python | upstream main | v0.25.0 | ahead of the release |
| ruby | tree-sitter/tree-sitter-ruby | v0.23.1 | v0.23.1 | current (= main) |
| rust | tree-sitter/tree-sitter-rust | v0.24.2 | v0.24.2 | current (= main) |
| scala | tree-sitter/tree-sitter-scala | v0.26.2 | v0.26.2 | current; updated 2 Oct 2026 from v0.26.0, upstream's query changes merged into ours |
| sql | DerekStride/tree-sitter-sql | v0.3.11 | v0.3.11 | current (upstream publishes generated sources only in releases) |
| swift | alex-pinkus/tree-sitter-swift | upstream main 35245fbf, generated here with CLI 0.25.10 | 0.7.3 | current; main adds SE-0458 `unsafe`, Swift 6.2 raw identifiers, case-pattern `where`, `if let … try await` |
| toml | tree-sitter-grammars/tree-sitter-toml | v0.7.0 | v0.7.0 | current (= main) |
| typescript, tsx | tree-sitter/tree-sitter-typescript | v0.23.2 | v0.23.2 | current (= main) |
| xml | tree-sitter-grammars/tree-sitter-xml | upstream main (Jan 2026; scanner UB fix) | v0.7.0 | current |
| yaml | tree-sitter-grammars/tree-sitter-yaml | v0.7.2 | v0.7.2 | current (= main) |

## Grammars generated here from upstream main

Swift and JSON publish generated sources only in releases, and both have important fixes on main that no release
carries yet. Their `src/` is generated here from upstream main with the tree-sitter CLI version that reproduces the
vendored release byte for byte (checked first: Swift 0.7.3 with CLI 0.25.x, JSON v0.24.8 with CLI 0.24.4 — only the
header comment differs), e.g. `npx tree-sitter-cli@0.25.10 generate` in a checkout of main. The checker reports
these as `unmatched`, since upstream has no committed `src/` to compare with. Return to a release once one ships.

## The runtime

`tree-sitter` 0.25.10 through SwiftTreeSitter 0.25.0 — both the newest usable. 0.25.10 is the last 0.25 release;
SwiftTreeSitter's main still pins `.upToNextMinor(from: "0.25.0")`, and upstream tree-sitter dropped its
`Package.swift` from 0.27.0. Every grammar above is ABI 14 or 15, which 0.25 accepts.

## Updating a grammar

Replace `src/` with upstream's generated sources for the new version. The `queries/` here carry LOCAL edits
(keyword tokens upstream leaves plain, revived patterns, receded import paths), so merge upstream's query changes
as a patch (`diff -u old/queries/highlights.scm new/queries/highlights.scm | patch -p0 queries/highlights.scm`),
never by copying. Then run `swift test`, and in the app `--probe-highlight-coverage <language>` and
`--selftest-highlight-roles ../TestFiles`: a query that stops compiling against a new grammar paints nothing,
silently, and only the bundle can show it.

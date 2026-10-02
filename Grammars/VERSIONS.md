# Vendored grammar versions

Which upstream version each grammar under `Grammars/` is, checked on 2 October 2026 by comparing the vendored
`src/grammar.json` with upstream's at every release tag and at HEAD. Re-check any time with
`scripts/check_grammar_versions.py` (exits 1 when a grammar is behind its latest release).

"Release" means the vendored grammar is byte-identical to that tag. "Upstream main" means it matches upstream's
head, which is ahead of the last tag (some repositories rarely tag).

| Grammar | Upstream | Vendored | Latest release | Status |
|---|---|---|---|---|
| bash | tree-sitter/tree-sitter-bash | v0.25.1 | v0.25.1 | current (= main) |
| c | tree-sitter/tree-sitter-c | v0.24.2 (= main) + local patch `sidewatch-c23.patch` | v0.24.2 | patched: C23 and extensions (see below) |
| cpp | tree-sitter/tree-sitter-cpp | upstream main + local patch `sidewatch-cpp23-26.patch`, generated against the patched C | v0.23.4 | patched: C++23/26 (see below) |
| csharp | tree-sitter/tree-sitter-c-sharp | upstream main | v0.23.5 | ahead of the release |
| css | tree-sitter/tree-sitter-css | v0.25.0 (= main) + local patch `sidewatch-modern-css.patch` | v0.25.0 | patched: modern CSS (see below) |
| dart | UserNobody14/tree-sitter-dart | upstream main | none tagged | current |
| dockerfile | camdencheek/tree-sitter-dockerfile | upstream main | v0.2.0 | ahead of the release |
| go | tree-sitter/tree-sitter-go | v0.25.0 | v0.25.0 | current (= main) |
| html | tree-sitter/tree-sitter-html | v0.23.2 | v0.23.2 | current (= main) |
| java | grammar-orchard/tree-sitter-java-orchard (codeberg) | v0.5.22 (7dc7faa) | v0.5.22 | current; the maintained fork (see below) |
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
| swift | alex-pinkus/tree-sitter-swift | upstream main 35245fbf + local patch `sidewatch-swift-6.patch`, generated with CLI 0.25.10 | 0.7.3 | patched: Swift 6 syntax (see below) |
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

## Local patches

**css — `tree-sitter-css/sidewatch-modern-css.patch`** (2 Oct 2026). Upstream v0.25.0 (also its main; ten open PRs,
the oldest from Nov 2025) put ERROR nodes on CSS browsers ship today, 512 in the corpus showcase. The patch adds:
Media Queries 4 range syntax, `@container` (named, `style()`, `scroll-state()`), `@layer` with dotted names,
`@page` selectors, `@function` with typed parameters and `returns`, `@import … layer() supports()`, `<type>` syntax
values (typed `attr()`), unquoted `url()`, attribute case flags, escapes in id names, all non-ASCII identifier
characters, `! important` spacing, fractional keyframe percentages, empty `;` statements, string line continuations,
and `&` ending a descendant selector (upstream PR #93's scanner line). Node names our queries use are unchanged.
Upstream's own tests pass (their expected trees updated where `@layer` and id names now have structure) plus a new
`test/corpus/modern.txt`. Not handled: `if()` (it explodes the generator's state count), the IE `*prop` hack, `<!--`
`-->` markers, and `{}` blocks inside custom-property values. `ModernCSSGrammarTests` fails on an unpatched parser.
To re-apply on a new upstream: `git am` the patch in a checkout, `tree-sitter generate` with CLI 0.25.10, copy `src/`.
Proposed upstream as tree-sitter/tree-sitter-css#105 (2 Oct 2026); drop the patch once a release carries it.

**swift — `tree-sitter-swift/sidewatch-swift-6.patch`** (2 Oct 2026). On top of upstream main 35245fbf: `sending` and
`isolated` parameter modifiers and `-> sending T` results, `isolated deinit`, `copy x`, value generics
(`<let rows: Int>`) and integer type arguments (`InlineArray<4, Int>`), inline array sugar (`[3 of Int]`), freestanding
macros with no arguments (`#isolation`), labeled version arguments (`@backDeployed(before: macOS 14)`), `[Int].Index?`, and a multiline extended regex whose closing `/#` is indented. The new keywords stay contextual (`let sending = 1` parses). Upstream's 292 tests pass unchanged;
new corpus `test/corpus/swift6.txt`. The parser grows 21.2 → 23.1 MB. Not handled: range patterns in `if case`
(upstream allows only non-expression patterns there), and the experimental `@lifetime` / underscored `@_specialize`.
`Swift6GrammarTests` fails on all 12 constructs with the unpatched parser.
Proposed upstream as alex-pinkus/tree-sitter-swift#629 (2 Oct 2026); drop the patch once a release carries it.

**c — `tree-sitter-c/sidewatch-c23.patch`** (2 Oct 2026). C23: `typeof`/`typeof_unqual`, `auto` inference,
`_BitInt(N)`, enums with any underlying type, `#embed` in initializers, `__has_include(<…>)` arguments,
`_Thread_local`, `[[attributes]]` after `*`, delimited and named escapes (`\x{41}`, `\N{…}`); C99 `_Complex`,
`_Pragma`; GNU case ranges and computed `goto *p`; MSVC `__ptr32/64` and `__declspec(align(16))`. Upstream's 87 tests pass; new corpus
`test/corpus/c23.txt`. `typeof` is coloured through an extra query on `.c` only, because the C++ grammar has no such
token and inherits the C query file.
Proposed upstream as tree-sitter/tree-sitter-c#331 (2 Oct 2026); drop the patch once a release carries it.

**cpp — `tree-sitter-cpp/sidewatch-cpp23-26.patch`** (2 Oct 2026). `if consteval`, contracts `pre`/`post`, pack
indexing `Ts...[0]` (`...[` one token so pack expansions are untouched), attributes on structured bindings,
explicit instantiation of class templates, attributes before `friend`, `= delete("reason")`, the `->*` operator,
pointer-to-member fields and typedefs (`int W::* p;`), and `= default` / `= delete` on functions outside a class
(upstream left a MISSING node, and read `friend … = default;` as a variable named `default`). Generated against the PATCHED C grammar
(`node_modules/tree-sitter-c` → the C checkout), so C's additions (`#embed`, `_Pragma`, case ranges, escapes) reach
C++ too; that needs two extra conflict entries in the C++ grammar. Upstream's tests pass.
Proposed upstream as tree-sitter/tree-sitter-cpp#375 (2 Oct 2026), generated against UPSTREAM tree-sitter-c, so
without those two conflicts and the escape tests; drop the patch once releases of both carry it.

**java — the grammar-orchard fork** (2 Oct 2026). tree-sitter/tree-sitter-java rarely merges outside PRs, and its
contributors maintain codeberg.org/grammar-orchard/tree-sitter-java-orchard (MIT, regular releases) instead. When our
Java 25 patch was proposed upstream (#233, closed), the fork already parsed every construct in it, so it replaced the
patch: `src/` generated from the fork's `grammar.js` with the 0.25.10 CLI (ABI 15; the fork ships no `parser.c`), its
LICENSE beside it, our `queries/` kept unchanged (every node they name exists in the fork). The fork names its
language `java_orchard`, so the binding header and `TreeSitterHighlighter` call `tree_sitter_java_orchard()`; the
SwiftPM target stays `TreeSitterJava`. To update: clone the fork, `tree-sitter generate`, copy `src/`.

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

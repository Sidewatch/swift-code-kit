# Audit log

Last full audit: **17 Sep 2026** — every source file covered by the MECHANICAL checks below (build warnings, tests,
dead-code and risk-pattern scans, docs drift); line-by-line logic review was targeted at the areas changed since
5 Sep 2026, not the whole tree. Nothing needs re-scanning unless it changed after that date. Add a dated line under *History* when you audit again, and keep the
*Known non-issues* list current so the next pass skips them.

## What a full audit checks

1. `swift build` warnings (none allowed except those listed under known non-issues) and `swift test` green.
2. Dead code: every `func`/type/property declared once and referenced nowhere in the app or the family
   (`grep -w` across `*.swift` AND non-Swift files — selectors and MCP names live in strings). Protocol
   requirements, `override`s, `@objc` actions and public API are NOT dead because Sidewatch does not call them.
3. Risky patterns: `Timer` without `invalidate`, `addObserver(forName:)` without `removeObserver`, `as!`, `try!`
   outside literal regexes, `fatalError` outside `init?(coder:)`, `print(` outside harnesses, TODO/FIXME left behind.
4. Docs drift: every name in CLAUDE.md's module map exists; AGENTS.md mirrors CLAUDE.md; README Usage matches the API.

## Result on 17 Sep 2026

- Build: clean. Tests: green.
- Fixed: `templateTagRegex`: dropped an unnecessary `nonisolated(unsafe)`.
- Fixed: Queries: revived dead patterns (later catch-alls outranked them) in Go, Python, Rust, PHP; Scala/Kotlin import lines; `@plain` role; `dumpCaptures` 30-char filter — see `65304fc` and the app's CLAUDE.md.

## Logic review — 18 Sep 2026 (every source and test file, line by line)

Fixed, each pinned by a test that fails against the old code:

- **A call was a breadcrumb scope.** `breadcrumbScopes` accepted any node whose type contains a
  definition word and that has a `name` field; Java's `method_invocation` and Lua's `function_call`
  satisfy both, so a caret inside a multi-line call's arguments read the CALLED method as an
  enclosing definition — `["A", "run", "call"]` for `other.call(1,\n 2)` — which grew a breadcrumb
  and pinned the call's line in sticky scroll. Node types containing `call` or `invocation` are
  skipped now (`call_signature` has no name field and was never a scope).
- **`colorFromHex("#+12345")` was a colour.** `UInt64(_:radix:)` accepts a leading sign; every
  character after the `#` must be a hex digit.
- **`url(//cdn…)` in SCSS/Less started a comment.** The stylesheet scanner exempted `//` only after a
  `:`; a protocol-relative unquoted URL follows `(`, and treating it as a comment swallowed the `;`
  that ended the `@import`, so the next rule's prelude began there and the outline listed
  `@import url( .a` (as a module) in place of `.a`.

Reviewed and sound: the grammar table and its lazy compile under a lock, `prunedQuerySource` /
`QuerySourceScanner`, `collectHits`' clip in source coordinates and the precedence windows,
`applyResolved`'s desired-run diff (zero writes on settled text — pinned by the
`didProcessEditingNotification` test), `injectionSites` / `mergeAscending` / `combinedParse`, the
template-tag masking, `HighlightSession` (the mirror kept in step by `noteEdit`, the desync drop, the
generation-stamped warm-up, the O(1) `currentTree` check), `ProjectSymbolIndex` (supersession by
generation, the mid-build replay, the one-batch rescan queue, the sorted-name cursor),
`SymbolQueries` and `visibleLanguages`, `SymbolOwners`, `CodeIndenter` (frozen interiors, the
closer-at-opener rule, the iterative walk), `ReceiverInference`, `EmbeddedMarkupHighlighter`'s region
scan and complement, `SyntaxHighlighter`'s one-pass string/comment merge, `HTTPRequestHighlighter`'s
state machine, `CustomLanguageDefinition`'s rule compile and friendly decode errors,
`CustomLanguageStore`'s per-file fingerprint, `MarkdownOutline` (fences, the 3-space cap, CRLF),
`StylesheetOutline` (banners, `//` banners, variables, the selector limit), `CompletionProvider`
(the empty-provider result deliberately not cached), `LanguageBuiltins` and `cardKind`. The module
map was missing `Rules/`, `Models/`, `Extensions/`, `SymbolKind`, `OutlineNode`, `StylesheetScanner`,
`SymbolOwners`, `SymbolQueries` and `CommentKeywords`; it lists every file now.

## Known non-issues (do not "fix" these again)

- `ResolvingQueryCursor` / `next()` deprecation warnings (3 sites): SwiftTreeSitter asks for `ResolvingQueryMatchSequence`. Deliberately left — the migration touches the hot query loop and wants its own measured change.
- `TreeSitterHighlighter.loadedCount` had no caller — removed 13 Oct 2026.
- `CommentKeywords.regex` is a `try!` on a literal pattern — fine.
- Grammar queries cannot load under `swift test` (Bundle.main); paint is proven by `Sidewatch --dump-captures` / `--probe-highlight-coverage`.
- Luau's long brackets in a scope scan's skip list are written out for levels 0 to 4 (`LuauRules`' `anyLevel`): a scan
  joins its patterns into one, where the backreference form would name another pattern's group. A long string or
  comment of level 5 or more is still painted whole by its own rule.
- Luau's built-in type names (`number`, `string`…) are types only after `:` or `->`, so `string.format` stays the
  library; inside a function type's brackets they stay plain, where Pygments and Shiki disagree and check nothing.
- Godot Resource keeps two accepted oracle entries (`scripts/highlight-oracle/accepted/gdresource.json` in the app):
  Shiki 3.23.0's grammar scopes a `type="…"` value and any `"res://…"` as code; Godot's variant parser reads both as
  strings.

## History

- 17 Sep 2026 — full audit (app + all 20 libraries), Claude with David.
- 18 Sep 2026 — logic review (every source and test file, line by line), Claude with David.
- 22 Sep 2026 — `Structure/YAMLStructure` added (the grammar already vendored for highlighting, read as ordered values); `YAMLStructureTests`.
- 22 Sep 2026 (later) — Markdown inline injection: chunks parsed one at a time (`separatelyParsed`), never combined — combined, two list items' code spans read as one and whole documents went string-coloured; pinned by `testMarkdownInlineChunksAreParsedSeparately`. `HighlightSession.fullParseCount` / `incrementalParseCount` are public for the app's `--dump-highlight --live`.
- 25 Sep 2026 — 20 rule tables for the languages a corpus sweep found flat or nearly so; `RuleTableCoverageTests` (three roles per table; the mutant that drops a mapping fails); the rule-table snapshot re-recorded.
- 25 Sep 2026 — nine more rule tables (BibTeX, DOT, EdgeQL, go.mod, MANIFEST.MF, Meson, Quarto/R Markdown, .strings, Texinfo); `YAMLStructure.site(in:path:)` (`YAMLEditSiteTests`; mutants: the pair's whole range and a reversed sequence each fail).
- 3 Oct 2026 — local grammar patches for bash 5.3 / escaped test operators, Dockerfile multi-name `ARG` and valueless flags, and the Swift typed-throws keyword (`Grammars/VERSIONS.md`), plus `defer` as a keyword in the Swift query; Quarto and R Markdown chunks painted in their own languages through `EmbeddedMarkupHighlighter` (one parse per language across all chunks, one table pass per language), front matter as YAML. `ShellDockerSwiftGrammarTests` (mutant: the unpatched grammars and query, 6 of 7 fail; the seventh is the `deferred` guard), `ExecutableMarkdownTests` (mutant: no chunk language, 4 of 7 fail; the other three pin fences, options and text blocks, which that mutant leaves alone).
- 9 Oct 2026 — corrupt-input pass (`DeepStructureTests`). Fixed: every structure reader converted a
  grammar's tree by one call per nesting level, so `a: [[[[…` 50,000 deep overflowed the main thread's
  stack in `YAMLStructure.convert` (the app crashed, signal 11, `KERN_PROTECTION_FAILURE` in the stack
  guard). `StructureDepth.limit` (256) now bounds `YAMLStructure.convert`, `TOMLStructure.build`,
  `XMLStructure.build` and `PlistStructure.build`; a value past it reads as `StructureDepth.exceeded`.
  Measured and fixed differently for XML: tree-sitter-xml's parse goes quadratic and error-ridden past
  about a thousand nested elements (0.08 s at 1,000, 2.0 s at 8,000, 167 s and a nil result at 50,000),
  so `XMLStructure.located` and `PlistStructure.located` refuse the depth BEFORE the parse with
  `StructureDepth.exceedsLimit(markup:)` — one linear pass counting tags, CDATA and comments skipped,
  leaving at the limit — and answer a one-row document that says so (4 ms at 50,000). Mutants: YAML and TOML
  unguarded each crash the test process (signal 11); XML unguarded returns nil after 167 s.
- 27 Oct 2026 — Luau and Godot Resource: rule tables (`LuauRules`, `GDResourceRules`) and regex outlines written from
  the official rules (luau.org's grammar and lexer and the Luau RFCs; Godot's TSCN format page and its variant
  parser), and checked by the app's oracle against Pygments 2.21.0 and Shiki 3.23.0: Luau has no differences, Godot
  two reasoned ones (above). `LuauRulesTests`, `GDResourceRulesTests` and the detection tests; 40 mutants, one per
  rule, all caught. Fixed on the way: `RuleScope` compiled its scan without `.anchorsMatchLines`, so a rule's own
  `.*$` comment passed as something to step over (Haxe's and SAS's `//`, Nix's `#`) matched only on a text's last
  line, and Stata's `^` comment line only on its first. An apostrophe in a Haxe `//` comment, or a quote in a Nix `#`
  comment, inverted every interpolated string after it (its text painted as code, the code between as string). The
  scan now reads `^` and `$` as every rule does (`RuleScopeTests`; the old options fail both); the whole corpus is
  unchanged (0 unexplained, 0 stale). New tests read paint through the shared `Tests/.../Support/PaintedKinds`; the
  older test files keep their own marker palettes.
- 29 Oct 2026 — two main-thread stalls found by Sidewatch's stall meter, fixed. (1) Every `HighlightSession` pass over a
  top-level HTML document ran the template-tag regex (`templateTagRanges`) over the whole text, read through the text
  storage a character at a time: 5.3–5.5 s a minimap slice on a 16 MB page (the same regex over a contiguous copy
  takes 135 ms). The session finds the tags once per edit (`TemplateTagMemo`, keyed by its generation) in its own
  UTF-16 mirror, and a range with no `<#` or `{{` is never searched (`mayHoldTemplateTag`); other callers search as
  before. (2) An injected language's grammar compiled on the main thread when a pass met it before the launch warm-up
  had (375 ms for Swift): `collectInjectionHits(awaitsGrammars:)` leaves it in the host's colours and
  `requestGrammar(_:)` compiles it in the background, once, announcing it through `onRequestedGrammarReady`. Opt-in:
  the session awaits; one-shot callers (Quick Look, snippets, dumps) still compile in place, since nothing would paint
  them again. Markdown's inline grammar now compiles with its block grammar. Tests: `TemplateTagMemoTests` (4),
  `HighlightSessionInjectionTests` (3: the session colours exactly as the searching highlighter, searched once per
  edit; a tag-free page never searched; an uncompiled injection compiled in the background and coloured when it
  lands), `GrammarWarmUpTests` (a request answers at once, compiles once, lands once); the shared
  `Tests/.../Support/SourceGrammars` builds HTML and JavaScript from the source tree. Mutants, each run and restored:
  the session compiling injections in the pass, the session asking no memo, the memo never forgetting a version,
  every range searched, the injection lookup ignoring `awaiting`, requests not deduplicated — all caught. A test seam,
  `mainThreadGrammarWaitsForTesting`, counts the main thread asking for a grammar not compiled yet (a compile or a wait
  on the thread that must never wait); a host's harness holds its promise to it (Sidewatch's first-use check), and its
  own test catches the count not being kept. 866 tests.

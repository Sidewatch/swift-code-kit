# Swift Code Kit

Source code, understood: which language a file is, and syntax highlighting for it — tree-sitter for 26 grammars, rule tables for the rest.

- Modules `CodeLanguage`, `CodeHighlighting`, each in `Sources/<Module>` with tests in `Tests/<Module>Tests`; `swift test` is the whole check.
- Swift 6 language mode, tools 6.2, macOS 14+.
- Part of the Sidewatch package family; every package follows the same layout and PR rules.
- Each module's user-facing documentation is `Docs/Modules/<Module>.md`; its last audit is `Docs/Audits/<Module>.md` — read it before auditing, and extend it rather than redo it.

## CodeLanguage — `Sources/CodeLanguage`

### Module map
- `Enums/` — enums with no behaviour beyond their cases and labels: HighlightFamily, Language
- `Extensions/` — extensions on Foundation / stdlib / other types: Language+Detection, Language+Metadata, Language+Names (`names(for:)`: every extension and exact filename the detector answers a language from, for a caller that needs to enumerate them — a corpus check asking "is there a fixture for every name we claim?")
- `Models/` — value types — the shape of a thing, nothing else: BlockComment

## CodeHighlighting — `Sources/CodeHighlighting`

### Module map
- `Builtins/` — bundled resources: one `<language>.txt` per language, `identifier⇥signature` per line
- `Completion/` — the engine: completion: CompletionProvider, LanguageBuiltins, LanguageBuiltins+CardKind
- `Core/` — the engine: CommentKeywords, CustomLanguageDefinition, CustomLanguageStore, EmbeddedMarkupHighlighter, HighlightTheme, HTTPRequestHighlighter, SyntaxHighlighter
- `Enums/` — enums with no behaviour beyond their cases and labels: SymbolKind, TokenKind
- `Errors/` — every Error type, one per file: CustomLanguageDefinitionError
- Shared Foundation helpers (`trimmed`, …) come from swift-foundation-extensions, not a local `Extensions/`.
- `Models/` — value types — the shape of a thing, nothing else: CompletionItem, CustomPattern, DefaultTokenColors, DefLocation, GrammarCoverage (+Gaps), UTF16NewlineScanner
- `Outline/` — the engine: outline: MarkdownOutline, OutlineNode, OutlineTree, StylesheetOutline
- `Structure/` — the documents read as ordered structure off the vendored grammars, all as swift-data-converter's `StructuredValue`: YAMLStructure (`value(of:)`, `documents(in:)`, `site(in:path:)`), TOMLStructure (tables, arrays of tables, dotted keys, every scalar kind), XMLStructure (attributes as `@name`, repeated children gathered into a sequence, text and `#text`, entities resolved), PlistStructure (an XML plist in file order with edit sites; a binary one through the converter's reader); LocatedValue / LocatedBuilder — the one walk that carries ranges, so a reader's tree and its edit sites can never disagree
- `Protocols/` — protocols the module exposes: CodeHighlighter, TokenColorProviding
- `Rules/` — the regex tables behind `SyntaxHighlighter`: RuleTables, RuleTables+Builders, one file per language under `Languages/`, one per family under `Families/`
- `Support/` — QuerySourceScanner (tree-sitter query forms), StylesheetScanner (one pass over a stylesheet), UTF16LineScanner (document lines as UTF-16 offsets)
- `TreeSitter/` — the engine: treesitter: CodeIndenter, HighlightSession, ProjectSymbolIndex, ReceiverInference, SymbolIndex, SymbolOwners, SymbolQueries, SymbolVisibility, TreeSitterHighlighter (+Coverage: a text against its grammar's own symbol table)
- `Grammars/` — the vendored grammars; `Grammars/VERSIONS.md` records which upstream version each is, `scripts/check_grammar_versions.py` re-checks them

## Rules

@CONTRIBUTING.md

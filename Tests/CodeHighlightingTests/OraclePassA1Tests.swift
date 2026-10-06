//
//  OraclePassA1Tests.swift
//  CodeHighlightingTests
//
//  SQL, Markdown, bash, Dockerfile, YAML, TOML and CSS queries and grammar patches, the code in Svelte, Astro
//  and Vue markup, and Quarto's Markdown paint what VS Code and Pygments agree on.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import CodeLanguage
import SwiftTreeSitter
import TreeSitterMarkdown
import TreeSitterMarkdownInline
import XCTest

@testable import CodeHighlighting

@MainActor
final class OraclePassA1Tests: XCTestCase {
    /// One colour per role, so a painted colour reads back as exactly one role.
    private struct Colours: TokenColorProviding {
        static let roles: [(TokenKind, String)] = [
            (.comment, "comment"), (.string, "string"), (.keyword, "keyword"), (.type, "type"), (.number, "number"),
            (.function, "function"), (.variable, "variable"), (.identifier, "identifier"), (.property, "property"),
            (.attribute, "attribute"),
        ]
        let foreground = NSColor(srgbRed: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        func color(for kind: TokenKind) -> NSColor {
            let index = Self.roles.firstIndex { $0.0 == kind } ?? 0
            return NSColor(srgbRed: CGFloat(index + 1) / 16, green: 0.5, blue: 0.25, alpha: 1)
        }
        func role(of colour: NSColor?) -> String {
            guard let c = colour, c != foreground else { return "plain" }
            return Self.roles.first { color(for: $0.0) == c }?.1 ?? "other"
        }
    }

    /// A painted text, read back by marker.
    private struct Painted {
        let storage: NSTextStorage
        let colours = Colours()

        /// The role on the first character of the `occurrence`-th `marker`.
        func role(_ marker: String, _ occurrence: Int = 1) -> String {
            let ns = storage.string as NSString
            var r = NSRange(location: 0, length: 0)
            for _ in 0..<occurrence {
                let from = NSMaxRange(r)
                r = ns.range(of: marker, range: NSRange(location: from, length: ns.length - from))
                if r.location == NSNotFound { return "missing \(marker)" }
            }
            return colours.role(of: storage.attribute(.foregroundColor, at: r.location, effectiveRange: nil) as? NSColor)
        }
    }

    private static let grammars = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().appendingPathComponent("Grammars")

    /// `text` painted by the vendored query file at `queries` (under `Grammars/`, read from the source tree: a test
    /// process has no query bundles beside it) over a parse by `language`.
    private func paint(_ text: String, _ language: SwiftTreeSitter.Language, queries: String) throws -> Painted {
        let colours = Colours()
        let saved = HighlightTheme.colors
        HighlightTheme.colors = colours
        defer { HighlightTheme.colors = saved }
        let source = try String(contentsOf: Self.grammars.appendingPathComponent(queries), encoding: .utf8)
        let query = try Query(language: language, data: Data(TreeSitterHighlighter.prunedQuerySource(source).utf8))
        let parser = Parser()
        try parser.setLanguage(language)
        let tree = try XCTUnwrap(parser.parse(text))
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colours.foreground])
        let clip = NSRange(location: 0, length: storage.length)
        var base = 0
        let hits = TreeSitterHighlighter.collectHits(query, tree: tree, source: text as NSString, offset: 0, clip: clip, nextBase: &base)
        TreeSitterHighlighter.applyResolved(hits: hits, clip: clip, defaultColor: colours.foreground, into: storage)
        return Painted(storage: storage)
    }

    /// `text` painted by `language`'s vendored grammar folder's `queries/highlights.scm`.
    private func paint(_ text: String, _ language: CodeLanguage.Language, folder: String) throws -> Painted {
        let ts = try XCTUnwrap(TreeSitterHighlighter.tsLanguage(for: language), "no grammar for \(language)")
        return try paint(text, ts, queries: "\(folder)/queries/highlights.scm")
    }

    /// `text` painted by the regex tier (or the embedded tier for a component or executable Markdown).
    private func paintTier(_ text: String, _ language: CodeLanguage.Language) -> Painted {
        let colours = Colours()
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colours.foreground])
        let full = NSRange(location: 0, length: storage.length)
        if let embedded = EmbeddedMarkupHighlighter(language: language, colors: colours) {
            embedded.highlight(storage, in: full)
        } else {
            SyntaxHighlighter(language: language, colors: colours).highlight(storage, in: full)
        }
        return Painted(storage: storage)
    }

    private func failingToParse(_ cases: [(String, String)], _ language: CodeLanguage.Language) -> [String] {
        cases.filter { TreeSitterHighlighter.parseErrorCount(in: $0.1, language: language) != 0 }.map(\.0)
    }

    // MARK: - SQL

    /// `DESC`, `DEFAULT`, `NULLS LAST`, `COLLATE` and `ARRAY` are keywords, not attributes or calls.
    func testSQLModifiersAreKeywords() throws {
        let p = try paint(
            "CREATE TABLE t (a INT DEFAULT 0, b TEXT ARRAY);\nSELECT a FROM t ORDER BY a DESC NULLS LAST;\n", .sql,
            folder: "tree-sitter-sql")
        XCTAssertEqual(p.role("DEFAULT"), "keyword")
        XCTAssertEqual(p.role("ARRAY"), "keyword")
        XCTAssertEqual(p.role("DESC"), "keyword")
        XCTAssertEqual(p.role("LAST"), "keyword")
    }

    /// Reserved words the grammar reads as names: `ROW(…)`, `ROLLUP (…)`, `DISTINCT ON (…)`, `AS IDENTITY`,
    /// `INTERVAL '2' HOUR`, `USE INDEX (PRIMARY)`, `VALUES (1, DEFAULT)`.
    func testSQLReservedWordsReadAsNamesAreKeywords() throws {
        let p = try paint(
            """
            SELECT ROW(1, 2) AS pair FROM t GROUP BY ROLLUP (a, b);
            SELECT DISTINCT ON (sku) sku FROM stock;
            CREATE TABLE g (id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY);
            SELECT INTERVAL '2' HOUR;
            SELECT * FROM m USE INDEX (PRIMARY) WHERE id = 1;
            INSERT INTO t (a, b) VALUES (1, DEFAULT);

            """, .sql, folder: "tree-sitter-sql")
        XCTAssertEqual(p.role("ROW"), "keyword")
        XCTAssertEqual(p.role("ROLLUP"), "keyword")
        XCTAssertEqual(p.role("ON"), "keyword")
        XCTAssertEqual(p.role("IDENTITY"), "keyword")
        XCTAssertEqual(p.role("HOUR"), "keyword")
        XCTAssertEqual(p.role("PRIMARY", 2), "keyword")
        XCTAssertEqual(p.role("DEFAULT"), "keyword")
    }

    /// A routine's `LANGUAGE SQL` and `COST 10`, a quoted identifier, `SET NAMES`, and MySQL / Hive table options.
    func testSQLRoutineAndTableOptions() throws {
        let p = try paint(
            """
            SELECT 1 AS "quoted identifier";
            CREATE FUNCTION f() RETURNS INT LANGUAGE SQL IMMUTABLE COST 10 AS $$ SELECT 1 $$;
            SET NAMES utf8mb4;
            CREATE TABLE m (id INT) ENGINE = InnoDB ROW_FORMAT=DYNAMIC COMMENT='table notes';
            CREATE TABLE h (id INT) STORED AS ORC TBLPROPERTIES ('transactional'='true');

            """, .sql, folder: "tree-sitter-sql")
        XCTAssertEqual(p.role("SQL"), "keyword")
        XCTAssertEqual(p.role("10"), "number")
        XCTAssertEqual(p.role("COST"), "keyword")
        XCTAssertEqual(p.role("quoted identifier"), "string")
        XCTAssertEqual(p.role("utf8mb4"), "plain")
        XCTAssertEqual(p.role("DYNAMIC"), "keyword")
        XCTAssertEqual(p.role("table notes"), "string")
        XCTAssertEqual(p.role("transactional"), "string")
        XCTAssertEqual(p.role("='true'"), "plain")
    }

    // MARK: - Bash

    /// A parameter expansion's operators and an all-elements subscript are code inside a string; the default
    /// word keeps the string colour.
    func testBashExpansionOperatorsAreCode() throws {
        let p = try paint(
            "echo \"${HOME:-/srv}\" \"${#list[@]}\" \"${!name}\" \"${path%/*}\" \"${@:2}\" \"$((n * 2))\"\n", .bash,
            folder: "tree-sitter-bash")
        XCTAssertEqual(p.role(":-"), "plain")
        XCTAssertEqual(p.role("srv"), "string")
        XCTAssertEqual(p.role("#list"), "plain")
        XCTAssertEqual(p.role("@]"), "plain")
        XCTAssertEqual(p.role("!name"), "plain")
        XCTAssertEqual(p.role("/*}"), "plain")
        XCTAssertEqual(p.role("@:"), "plain")
        XCTAssertEqual(p.role("* 2"), "plain")
    }

    /// Backticks, a backslash-escaped word and a decimal word.
    func testBashBackticksEscapesAndDecimals() throws {
        let p = try paint("legacy=`uname -s`\necho \\$notvar \\' 3.14159\nkill -9 -- -\"$pid\"\n", .bash, folder: "tree-sitter-bash")
        XCTAssertEqual(p.role("`uname"), "string")
        XCTAssertEqual(p.role("\\$notvar"), "string")
        XCTAssertEqual(p.role("\\'"), "string")
        XCTAssertEqual(p.role("3.14159"), "number")
        XCTAssertEqual(p.role("\"$pid"), "string")
        XCTAssertEqual(p.role("pid"), "property")
    }

    // MARK: - Dockerfile

    /// The quoting patch: JSON-form ADD and COPY with flags, quoted paths and stage names, and escapes in an
    /// unquoted value parse without errors.
    func testDockerfileQuotingParses() {
        let cases = [
            ("JSON-form ADD with flags", "ADD --chown=1000:1000 --chmod=755 [\"archive.tar.gz\", \"/opt/\"]\n"),
            ("JSON-form COPY", "COPY [\"file with spaces.txt\", \"/dest/\"]\n"),
            ("quoted COPY paths", "COPY 'src one' \"dest two\"\n"),
            ("quoted WORKDIR", "WORKDIR '/opt/quoted dir'\n"),
            ("quoted stage name", "FROM alpine AS \"quoted-stage\"\nFROM ${REGISTRY:-docker.io}/library/alpine:latest\n"),
            ("escapes in an unquoted value", "ENV LITERAL=\\$NOT_EXPANDED ESC_SPACE=two\\ words\n"),
        ]
        XCTAssertEqual(failingToParse(cases, .dockerfile), [])
    }

    /// Those strings paint as strings; a heredoc's lines are plain text, a comment line in one a comment.
    func testDockerfileStringsAndHeredocLines() throws {
        let p = try paint(
            """
            COPY ["file with spaces.txt", "/dest/"]
            WORKDIR '/opt/quoted dir'
            ENV ESC_SPACE=two\\ words
            RUN <<EOT
            #!/bin/sh
            mkdir -p /opt/app
            EOT

            """, .dockerfile, folder: "tree-sitter-dockerfile")
        XCTAssertEqual(p.role("file with"), "string")
        XCTAssertEqual(p.role("/opt/quoted"), "string")
        XCTAssertEqual(p.role("\\ words"), "string")
        XCTAssertEqual(p.role("#!/bin/sh"), "comment")
        XCTAssertEqual(p.role("mkdir"), "plain")
    }

    // MARK: - YAML

    /// A directive's version and tag handle, the YAML 1.1 `y`/`n` booleans and timestamps.
    func testYAMLDirectivesBooleansAndTimestamps() throws {
        let p = try paint(
            "%YAML 1.2\n%TAG !e! tag:example.com,2026:\n---\na: y\nb: 2026-03-01\nc: 2026-03-01T09:30:00Z\nd: 2026-3\n", .yaml,
            folder: "tree-sitter-yaml")
        XCTAssertEqual(p.role("1.2"), "number")
        XCTAssertEqual(p.role("!e!"), "keyword")
        XCTAssertEqual(p.role("y"), "number")
        XCTAssertEqual(p.role("2026-03-01"), "number")
        XCTAssertEqual(p.role("2026-03-01T"), "number")
        XCTAssertEqual(p.role("2026-3"), "string")
    }

    // MARK: - TOML

    /// The TOML 1.1 patch: `\e` and `\xHH` escapes and times without seconds parse; dates are constants.
    func testTOMLOnePointOneParsesAndDatesAreConstants() throws {
        let cases = [
            ("new escapes", "a = \"escape \\e and hex \\x41\\x7a\"\n"),
            ("times without seconds", "t = 07:32\nd = 1979-05-27T07:32\no = 1979-05-27T07:32Z\n"),
        ]
        XCTAssertEqual(failingToParse(cases, .toml), [])
        let p = try paint("d = 1979-05-27\nt = 07:32:00\n", .toml, folder: "tree-sitter-toml")
        XCTAssertEqual(p.role("1979"), "number")
        XCTAssertEqual(p.role("07:32"), "number")
    }

    // MARK: - CSS

    /// The unit patch: `16px/1.5` is a length over a number, not `16` and the word `px/1.5`.
    func testCSSUnitBeforeASlash() throws {
        XCTAssertEqual(failingToParse([("font shorthand", "a { font: 16px/1.5 serif; }\n")], .css), [])
        let p = try paint("a { font: 16px/1.5 serif; }\n", .css, folder: "tree-sitter-css")
        XCTAssertEqual(p.role("px"), "type")
        XCTAssertEqual(p.role("1.5"), "number")
    }

    /// A hex colour is a constant, an unquoted `url()` argument is not a string, `an+b` is a number.
    func testCSSColoursURLsAndNthArguments() throws {
        let p = try paint(
            "a { color: #aabbccdd; background: url(img/a.png); }\nli:nth-child(2n + 1) { margin: 0; }\n", .css,
            folder: "tree-sitter-css")
        XCTAssertEqual(p.role("#aabb"), "number")
        XCTAssertEqual(p.role("img/a.png"), "plain")
        XCTAssertEqual(p.role("2n"), "number")
    }

    // MARK: - Markdown

    /// A hard line break (a backslash ending a line) is punctuation, not an escape.
    func testMarkdownHardLineBreakIsPlain() throws {
        let p = try paint(
            "Line one\\\nnext \\* line\n", SwiftTreeSitter.Language(tree_sitter_markdown_inline()),
            queries: "tree-sitter-markdown/tree-sitter-markdown-inline/queries/highlights.scm")
        XCTAssertEqual(p.role("\\\n"), "plain")
        XCTAssertEqual(p.role("\\*"), "string")
    }

    /// A table cell's content is inline Markdown: the block grammar's injections hand it to the inline grammar.
    func testMarkdownTableCellsAreInjectedAsInline() throws {
        let language = SwiftTreeSitter.Language(tree_sitter_markdown())
        let source = try String(
            contentsOf: Self.grammars.appendingPathComponent("tree-sitter-markdown/tree-sitter-markdown/queries/injections.scm"),
            encoding: .utf8)
        let query = try Query(language: language, data: Data(source.utf8))
        let text = "| a | b |\n|---|---|\n| `code` | [link](#x) |\n"
        let parser = Parser()
        try parser.setLanguage(language)
        let tree = try XCTUnwrap(parser.parse(text))
        let cursor = query.execute(in: tree)
        var cells: [String] = []
        while let match = cursor.next() {
            for capture in match.captures where capture.name == "injection.content" && capture.node.nodeType == "pipe_table_cell" {
                cells.append((text as NSString).substring(with: capture.range))
            }
        }
        XCTAssertTrue(cells.contains { $0.hasPrefix("[link](#x)") }, "cells injected: \(cells)")
    }

    // MARK: - Component markup

    /// Svelte's markup: a numeric attribute value is a number between string quotes, quotes in text are text,
    /// every directive's prefix is an attribute, and `{#each … as` is a keyword up to `as`.
    func testSvelteMarkupTable() {
        let p = paintTier(
            "<input min=\"0\" max=\"1rem\" value=\"text\" />\n<p>Say \"hi\"</p>\n<p transition:fade in:fly out:slide>x</p>\n"
                + "{#each items as item}{/each}\n", .svelte)
        XCTAssertEqual(p.role("0\""), "number")
        XCTAssertEqual(p.role("\"0"), "string")
        XCTAssertEqual(p.role("1rem"), "number")
        XCTAssertEqual(p.role("text"), "string")
        XCTAssertEqual(p.role("max"), "plain")
        XCTAssertEqual(p.role("hi"), "plain")
        XCTAssertEqual(p.role("transition"), "attribute")
        XCTAssertEqual(p.role("in:fly"), "attribute")
        XCTAssertEqual(p.role(" as"), "keyword")
    }

    /// The code in Svelte markup: expressions, block tags' code (a snippet's signature as a function, `{@const}`
    /// as a declaration, only the list of an `{#each}`), and expressions inside a quoted attribute value.
    func testSvelteExpressions() {
        let text = """
            {#if count > 0}<p>{count}</p>{:else if ok}{/if}
            {#each items as item, i (item.id)}{/each}
            {#snippet row(item: Item)}{/snippet}
            {@const label = `${a} b`}
            <meta content="for {items.length} items" />
            <!-- {not code} -->

            """
        let found = TemplateExpressionScanner.svelte(in: text as NSString, gaps: [NSRange(location: 0, length: (text as NSString).length)])
        let bodies = found.map { (text as NSString).substring(with: $0.body) }
        XCTAssertEqual(bodies, ["count > 0", "count", "ok", "items", "row(item: Item)", "label = `${a} b`", "items.length"])
        XCTAssertEqual(found.first { (text as NSString).substring(with: $0.body).hasPrefix("row") }?.prefix, "function ")
        XCTAssertEqual(found.first { (text as NSString).substring(with: $0.body).hasPrefix("label") }?.prefix, "const ")
        XCTAssertEqual(found.first { (text as NSString).substring(with: $0.body) == "count" }?.braces.count, 2)
    }

    /// Astro's expressions skip a quoted attribute value, whose braces are text, and pass over strings and
    /// template literals holding a brace; each is wrapped to parse as the fragment it is.
    func testAstroExpressions() {
        let text = "<div data-json='{\"k\": 1}' title={`a ${b} }`} {...rest}>{items.map((i) => <li>{i}</li>)}{/* note */}</div>\n"
        let found = TemplateExpressionScanner.astro(in: text as NSString, gaps: [NSRange(location: 0, length: (text as NSString).length)])
        XCTAssertEqual(
            found.map { (text as NSString).substring(with: $0.body) },
            ["`a ${b} }`", "...rest", "items.map((i) => <li>{i}</li>)", "/* note */"])
        // A spread parses inside an array literal, a lone comment as it is, anything else inside parentheses.
        XCTAssertEqual(found.map(\.prefix), ["(", "[", "(", ""])
    }

    /// Vue's expressions: `{{ … }}`, a bound or conditional directive's value, a handler's statements, and a `v-for` as
    /// a loop's head.
    func testVueExpressions() {
        let text = "<li v-for=\"(item, i) in items\" :key=\"item.id\" @click=\"count++\" class=\"plain\">{{ `n ${count}` }}</li>\n"
        let found = TemplateExpressionScanner.vue(in: text as NSString, gaps: [NSRange(location: 0, length: (text as NSString).length)])
        XCTAssertEqual(
            found.map { (text as NSString).substring(with: $0.body) }, ["(item, i) in items", "item.id", "count++", "`n ${count}`"])
        XCTAssertEqual(found.first { (text as NSString).substring(with: $0.body) == "count++" }?.prefix, "")
        XCTAssertEqual(found.first?.prefix, "for (")
    }

    /// A Vue custom block that names its language (`<i18n lang="json">`) is a region in that language; one that names
    /// none (`<docs>`) stays markup.
    func testVueCustomBlocksAreRegions() {
        let text = "<template><p>x</p></template>\n<i18n lang=\"json\">\n{ \"en\": 1 }\n</i18n>\n<docs>\nText\n</docs>\n"
        let ns = text as NSString
        let regions = EmbeddedMarkupHighlighter.regions(in: ns, language: .vue)
        XCTAssertEqual(regions.map(\.language), [.json])
        XCTAssertEqual(regions.first.map { ns.substring(with: $0.range) }, "\n{ \"en\": 1 }\n")
    }

    /// Astro's markup: quotes and JavaScript words in its text are text; an attribute's value is a string.
    func testAstroMarkupText() {
        let p = paintTier("---\nconst a = 1;\n---\n<p title=\"Tip\">Say \"hi\" for all of them</p>\n", .astro)
        XCTAssertEqual(p.role("Tip"), "string")
        XCTAssertEqual(p.role("hi"), "plain")
        XCTAssertEqual(p.role("for"), "plain")
    }

    /// Astro's frontmatter fences are comments, as VS Code scopes them.
    func testAstroFrontmatterFencesAreComments() {
        let p = paintTier("---\nconst a = 1;\n---\n<p>x</p>\n", .astro)
        XCTAssertEqual(p.role("---"), "comment")
        XCTAssertEqual(p.role("---", 2), "comment")
    }

    // MARK: - Quarto

    /// Quarto's Markdown: a block quote's text is text (its markers are comments), a setext underline is a
    /// keyword, a backslash escape, a link's title and an HTML attribute's value are strings.
    func testQuartoMarkdown() {
        let p = paintTier(
            """
            ---
            title: x
            ---
            > A block quote

            Setext heading
            --------------

            Escapes: \\* \\_ and [a link](https://example.com "Title").

            <div class="note">

            ```
            A fenced block without a language.
            ```

            """, .quarto)
        XCTAssertEqual(p.role(">"), "comment")
        XCTAssertEqual(p.role("A block"), "plain")
        XCTAssertEqual(p.role("-----"), "keyword")
        XCTAssertEqual(p.role("\\*"), "string")
        XCTAssertEqual(p.role("Title"), "string")
        XCTAssertEqual(p.role("note"), "string")
    }
}

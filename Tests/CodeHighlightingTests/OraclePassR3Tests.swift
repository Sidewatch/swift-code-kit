//
//  OraclePassR3Tests.swift
//  CodeHighlightingTests
//
//  Annotations wear the attribute colour in every tree-sitter language while markup attribute names keep the
//  property colour; Dockerfile shell injections, the Markdown HTML block and template-tag fixes, and the regex
//  tables the third accuracy round corrected (Git config, INI, Haskell, Move, Nushell, Razor, Markdown links,
//  Smarty, SML, Velocity, Elixir, Crystal).
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import CodeLanguage
import SwiftTreeSitter
import XCTest

@testable import CodeHighlighting

@MainActor
final class OraclePassR3Tests: XCTestCase {
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

        /// The role every character of the `occurrence`-th `marker` wears, or "mixed".
        func wholeRole(_ marker: String, _ occurrence: Int = 1) -> String {
            let ns = storage.string as NSString
            var r = NSRange(location: 0, length: 0)
            for _ in 0..<occurrence {
                let from = NSMaxRange(r)
                r = ns.range(of: marker, range: NSRange(location: from, length: ns.length - from))
                if r.location == NSNotFound { return "missing \(marker)" }
            }
            let roles = Set(
                (r.location..<NSMaxRange(r)).map {
                    colours.role(of: storage.attribute(.foregroundColor, at: $0, effectiveRange: nil) as? NSColor)
                })
            return roles.count == 1 ? roles.first! : "mixed"
        }
    }

    private static let grammars = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().appendingPathComponent("Grammars")

    /// `text` painted by the vendored query files `queries` (under `Grammars/`, read from the source tree and
    /// joined in order, as a grammar that inherits another's query is) over a parse by `language`.
    private func paint(_ text: String, _ language: CodeLanguage.Language, queries: [String]) throws -> Painted {
        let ts = try XCTUnwrap(TreeSitterHighlighter.tsLanguage(for: language), "no grammar for \(language)")
        let colours = Colours()
        let saved = HighlightTheme.colors
        HighlightTheme.colors = colours
        defer { HighlightTheme.colors = saved }
        let source = try queries.map { try String(contentsOf: Self.grammars.appendingPathComponent($0), encoding: .utf8) }
            .joined(separator: "\n")
        let query = try Query(language: ts, data: Data(TreeSitterHighlighter.prunedQuerySource(source).utf8))
        let parser = Parser()
        try parser.setLanguage(ts)
        let tree = try XCTUnwrap(parser.parse(text))
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colours.foreground])
        let clip = NSRange(location: 0, length: storage.length)
        var base = 0
        let hits = TreeSitterHighlighter.collectHits(query, tree: tree, source: text as NSString, offset: 0, clip: clip, nextBase: &base)
        TreeSitterHighlighter.applyResolved(hits: hits, clip: clip, defaultColor: colours.foreground, into: storage)
        return Painted(storage: storage)
    }

    /// `text` painted by `language`'s vendored `queries/highlights.scm` in grammar folder `folder`.
    private func paint(_ text: String, _ language: CodeLanguage.Language, folder: String) throws -> Painted {
        try paint(text, language, queries: ["\(folder)/queries/highlights.scm"])
    }

    /// `text` painted by the whole tree-sitter highlighter for `language`, injections included, with `grammars`
    /// built from the source tree (each with the host flags its builder sets) and installed in the cache for the
    /// test's length.
    private func paintFull(_ text: String, _ language: CodeLanguage.Language, grammars: [CodeLanguage.Language: TestGrammar]) throws
        -> Painted
    {
        for (lang, spec) in grammars {
            let ts = try XCTUnwrap(TreeSitterHighlighter.tsLanguage(for: lang), "no grammar for \(lang)")
            let built = try XCTUnwrap(TreeSitterHighlighter.grammarBuilders[lang]?(), "no builder for \(lang)")
            let highlights =
                try spec.lead
                + spec.highlights.map { try String(contentsOf: Self.grammars.appendingPathComponent($0), encoding: .utf8) }
                .joined(separator: "\n")
            let injections =
                try spec.injections.map { try String(contentsOf: Self.grammars.appendingPathComponent($0), encoding: .utf8) }
                .joined(separator: "\n") + spec.extraInjections
            TreeSitterHighlighter.installGrammarForTesting(
                .init(
                    language: ts, highlights: try Query(language: ts, data: Data(TreeSitterHighlighter.prunedQuerySource(highlights).utf8)),
                    injections: injections.isEmpty ? nil : try Query(language: ts, data: Data(injections.utf8)),
                    templateTags: built.templateTags, htmlTemplateTags: built.htmlTemplateTags, separateInjections: built.separateInjections
                ),
                for: lang)
        }
        defer { for lang in grammars.keys { TreeSitterHighlighter.forgetGrammarForTesting(lang) } }
        let colours = Colours()
        let saved = HighlightTheme.colors
        HighlightTheme.colors = colours
        defer { HighlightTheme.colors = saved }
        let highlighter = try XCTUnwrap(TreeSitterHighlighter(language: language), "grammar not loaded")
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colours.foreground])
        highlighter.highlight(storage, in: NSRange(location: 0, length: storage.length))
        return Painted(storage: storage)
    }

    /// A grammar's query files under `Grammars/`: a lead pattern and an extra injection where its builder adds them.
    private struct TestGrammar {
        var lead = ""
        var highlights: [String]
        var injections: [String] = []
        var extraInjections = ""
    }

    /// `text` painted by the regex tier (or the embedded tier for executable Markdown).
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

    // MARK: - Attributes

    /// An annotation capture is the attribute role (the type colour in the app); a markup attribute name is the
    /// property role; `identifier.name` is a plain name a later pattern claims.
    func testCaptureRoles() {
        for capture in ["attribute", "annotation", "decorator", "attribute.builtin"] {
            XCTAssertEqual(TreeSitterHighlighter.role(for: capture), "attribute", capture)
        }
        XCTAssertEqual(TreeSitterHighlighter.role(for: "tag.attribute"), "property")
        XCTAssertEqual(TreeSitterHighlighter.role(for: "property"), "property")
        XCTAssertEqual(TreeSitterHighlighter.role(for: "identifier.name"), "identifier")
    }

    /// Java, Kotlin, C#, Dart, PHP, Scala, Swift: the annotation's name wears the attribute colour, its arguments
    /// their own.
    func testAnnotationsWearTheAttributeColour() throws {
        let java = try paint(
            "class A {\n  @Override public String toString() { return \"\"; }\n  @SuppressWarnings(\"unchecked\") void f() {}\n}\n",
            .java, folder: "tree-sitter-java")
        XCTAssertEqual(java.role("@Override"), "attribute")
        XCTAssertEqual(java.role("Override"), "attribute")
        XCTAssertEqual(java.role("SuppressWarnings"), "attribute")
        XCTAssertEqual(java.role("\"unchecked\""), "string")
        let kotlin = try paint("@JvmStatic fun f() {}\n", .kotlin, folder: "tree-sitter-kotlin")
        XCTAssertEqual(kotlin.role("JvmStatic"), "attribute")
        let csharp = try paint("[Serializable]\nclass A {}\n", .csharp, folder: "tree-sitter-csharp")
        XCTAssertEqual(csharp.role("Serializable"), "attribute")
        let dart = try paint("@override\nvoid f() {}\n", .dart, folder: "tree-sitter-dart")
        XCTAssertEqual(dart.role("override"), "attribute")
        let php = try paint("<?php\n#[Deprecated(\"x\")]\nfunction f() {}\n", .php, folder: "tree-sitter-php")
        XCTAssertEqual(php.role("Deprecated"), "attribute")
        let scala = try paint("@tailrec def f(n: Int): Int = n\n", .scala, folder: "tree-sitter-scala")
        XCTAssertEqual(scala.role("tailrec"), "attribute")
        let swift = try paint("@MainActor final class A {}\n", .swift, folder: "tree-sitter-swift")
        XCTAssertEqual(swift.role("@MainActor"), "attribute")
        XCTAssertEqual(swift.role("MainActor"), "attribute")
    }

    /// A Python or JavaScript decorator's `@` and name are the attribute; its arguments keep their own colours
    /// (the Python query painted the whole decorator, arguments included, as a call).
    func testDecoratorsWearTheAttributeColour() throws {
        let python = try paint(
            "@dataclass(frozen=True)\nclass A:\n    pass\n\n@app.route(\"/x\")\ndef f():\n    pass\n", .python,
            folder: "tree-sitter-python")
        XCTAssertEqual(python.role("@dataclass"), "attribute")
        XCTAssertEqual(python.role("dataclass"), "attribute")
        XCTAssertNotEqual(python.role("frozen"), "function")
        XCTAssertNotEqual(python.role("frozen"), "attribute")
        XCTAssertEqual(python.role("route"), "attribute")
        XCTAssertEqual(python.role("\"/x\""), "string")
        let js = try paint(
            "@logged\nclass A {\n  @bound method() {}\n}\n", .javascript, folder: "tree-sitter-javascript")
        XCTAssertEqual(js.role("@logged"), "attribute")
        XCTAssertEqual(js.role("logged"), "attribute")
        XCTAssertEqual(js.role("bound"), "attribute")
    }

    /// C and C++ standard attributes (`[[nodiscard]]`, `[[gnu::cold]]`) name an attribute; the C query is
    /// prepended to the C++ one.
    func testCAndCppAttributesWearTheAttributeColour() throws {
        let c = try paint("[[nodiscard]] int f(void);\n[[gnu::cold]] void g(void);\n", .c, folder: "tree-sitter-c")
        XCTAssertEqual(c.role("nodiscard"), "attribute")
        XCTAssertEqual(c.role("gnu"), "attribute")
        XCTAssertEqual(c.role("cold"), "attribute")
        let cpp = try paint(
            "[[nodiscard]] int f();\n", .cpp,
            queries: ["tree-sitter-c/queries/highlights.scm", "tree-sitter-cpp/queries/highlights.scm"])
        XCTAssertEqual(cpp.role("nodiscard"), "attribute")
    }

    /// A Rust attribute's `#[ ]` and path are the attribute; its arguments keep their own colours (the item
    /// was painted whole before).
    func testRustAttributeNameNotItsArguments() throws {
        let rust = try paint("#[derive(Debug, Clone)]\n#![allow(dead_code)]\nstruct A;\n", .rust, folder: "tree-sitter-rust")
        XCTAssertEqual(rust.role("#["), "attribute")
        XCTAssertEqual(rust.role("derive"), "attribute")
        XCTAssertEqual(rust.role("allow"), "attribute")
        XCTAssertNotEqual(rust.role("Debug"), "attribute")
        XCTAssertNotEqual(rust.role("dead_code"), "attribute")
        XCTAssertEqual(rust.role("("), "plain")
    }

    /// A markup attribute name (`class=`, a JSX prop, a CSS pseudo-class or attribute selector) keeps the
    /// property colour; upstream queries spell it `@attribute`.
    func testMarkupAttributeNamesKeepThePropertyColour() throws {
        let html = try paint("<a href=\"x\" class=\"y\">z</a>\n", .html, folder: "tree-sitter-html")
        XCTAssertEqual(html.role("href"), "property")
        XCTAssertEqual(html.role("class"), "property")
        let jsx = try paint(
            "const a = <div className=\"x\" onClick={f} />;\n", .javascript,
            queries: ["tree-sitter-javascript/queries/highlights.scm", "tree-sitter-javascript/queries/highlights-jsx.scm"])
        XCTAssertEqual(jsx.role("className"), "property")
        XCTAssertEqual(jsx.role("onClick"), "property")
        let css = try paint("a:hover, [href] { color: red }\n", .css, folder: "tree-sitter-css")
        XCTAssertEqual(css.role("hover"), "property")
        XCTAssertEqual(css.role("href"), "property")
    }

    /// A YAML directive and an XML DTD attribute default are keywords, not annotations.
    func testDirectivesAreKeywords() throws {
        let yaml = try paint("%YAML 1.2\n---\na: 1\n", .yaml, folder: "tree-sitter-yaml")
        XCTAssertEqual(yaml.role("%YAML"), "keyword")
        let xml = try paint(
            "<!DOCTYPE note [\n<!ATTLIST note id ID #REQUIRED>\n]>\n<note id=\"a\"/>\n", .xml, folder: "tree-sitter-xml")
        XCTAssertEqual(xml.role("#REQUIRED"), "keyword")
    }

    // MARK: - Tree-sitter queries

    /// `fun` is a hard keyword even where the grammar misparses the construct around it (context parameters).
    func testKotlinFunInAMisparseIsAKeyword() throws {
        let kotlin = try paint("context(String) fun f() {}\n", .kotlin, folder: "tree-sitter-kotlin")
        XCTAssertEqual(kotlin.role("fun"), "keyword")
    }

    /// A Scala end marker's name: a type's in the type colour, a term's a plain name, a keyword's a keyword.
    func testScalaEndMarkerNames() throws {
        let scala = try paint(
            "object Recent:\n  def m(n: Int): Int =\n    n + 1\n  end m\n  extension (s: String)\n    def twice = s + s\n  end extension\nend Recent\n",
            .scala, folder: "tree-sitter-scala")
        XCTAssertEqual(scala.role("Recent", 2), "type")
        XCTAssertEqual(scala.role("m\n  extension"), "identifier")
        XCTAssertEqual(scala.role("extension", 2), "keyword")
        XCTAssertEqual(scala.role("end", 3), "keyword")
    }

    // MARK: - Dockerfile, Markdown

    /// Shell-form commands and heredocs are bash, each its own document: an apostrophe in one command does not
    /// run into the next, and a heredoc's lines parse together, line breaks included. `RUN python3 <<PY` is
    /// Python.
    func testDockerfileShellIsInjectedPerCommand() throws {
        let text = """
            FROM alpine
            CMD echo it's
            RUN echo "built" && make
            RUN <<EOT
            #!/bin/sh
            echo "heredoc"
            EOT
            RUN python3 <<PY
            print("py")
            PY

            """
        let p = try paintFull(
            text, .dockerfile,
            grammars: [
                .dockerfile: TestGrammar(
                    highlights: ["tree-sitter-dockerfile/queries/highlights.scm"],
                    injections: ["tree-sitter-dockerfile/queries/injections.scm"]),
                .bash: TestGrammar(highlights: ["tree-sitter-bash/queries/highlights.scm"]),
                .python: TestGrammar(highlights: ["tree-sitter-python/queries/highlights.scm"]),
            ])
        XCTAssertEqual(p.role("echo", 2), "function")
        XCTAssertEqual(p.role("\"built\""), "string")
        XCTAssertEqual(p.role("#!/bin/sh"), "comment")
        XCTAssertEqual(p.role("echo", 3), "function")
        XCTAssertEqual(p.role("\"heredoc\""), "string")
        XCTAssertEqual(p.role("print"), "function")
        XCTAssertEqual(p.role("EOT", 2), "keyword")
    }

    /// `<!DOCTYPE html>` opens an HTML block that ends at its line (the vendored grammar's type-4 block ran to the
    /// end of the document when the `>` followed other text).
    func testMarkdownDoctypeBlockEnds() throws {
        let tree = try XCTUnwrap(TreeSitterHighlighter.syntaxTree(of: "<!DOCTYPE html>\n\nA paragraph.\n", language: .markdown))
        XCTAssertTrue(tree.contains("(paragraph"), tree)
    }

    /// HTML inside Markdown is not scanned for WordPress template tags; a PHP page's HTML still is.
    func testTemplateTagsOnlyInPHPHostedHTML() throws {
        let html = TestGrammar(
            highlights: ["tree-sitter-html/queries/highlights.scm"], injections: ["tree-sitter-html/queries/injections.scm"])
        let javascript = TestGrammar(
            lead: "(identifier) @identifier.plain\n", highlights: ["tree-sitter-javascript/queries/highlights.scm"])
        let markdown = try paintFull(
            "<div>\n{{ variable }}\n</div>\n", .markdown,
            grammars: [
                .markdown: TestGrammar(
                    highlights: ["tree-sitter-markdown/tree-sitter-markdown/queries/highlights.scm"],
                    injections: ["tree-sitter-markdown/tree-sitter-markdown/queries/injections.scm"]),
                .html: html, .javascript: javascript,
            ])
        XCTAssertEqual(markdown.role("variable"), "plain")
        let php = try paintFull(
            "<?php $a = 1; ?>\n<div>{{ variable }}</div>\n", .php,
            grammars: [
                .php: TestGrammar(
                    highlights: ["tree-sitter-php/queries/highlights.scm"], injections: ["tree-sitter-php/queries/injections.scm"],
                    extraInjections: "\n((text) @injection.content (#set! injection.language \"html\"))\n"),
                .html: html, .javascript: javascript,
            ])
        XCTAssertNotEqual(php.role("variable"), "plain")
    }

    // MARK: - Regex tables

    /// A Git config boolean or number is the whole value: words inside a command line, a revision or a URL are not.
    func testGitConfigValuesAreWholeValues() {
        let p = paintTier(
            "[alias]\n\tamend = commit --no-edit\n\tundo = reset HEAD~1\n\turl = https://x.example/?a=1&b=2\n[core]\n\tabbrev = 12\n\tprune = true\n\tyes = maybe\n",
            .gitconfig)
        XCTAssertEqual(p.role("no-edit"), "plain")
        XCTAssertEqual(p.role("1\n"), "plain")
        XCTAssertEqual(p.role("2\n"), "plain")
        XCTAssertEqual(p.role("12"), "number")
        XCTAssertEqual(p.role("true"), "number")
        XCTAssertEqual(p.role("yes"), "function")
    }

    /// An INI boolean is the whole value, a dotted address is not a number, and an interpolation runs to its brace.
    func testINIValues() {
        let p = paintTier(
            "[s]\nprose = turn it on later\nip = 127.0.0.1\nport = 8080\npath = ${paths:data}/x\nflag = on\n", .ini)
        XCTAssertEqual(p.role("on later"), "plain")
        XCTAssertEqual(p.role("127"), "plain")
        XCTAssertEqual(p.role("0.1"), "plain")
        XCTAssertEqual(p.role("8080"), "number")
        XCTAssertEqual(p.wholeRole("${paths:data}"), "type")
        XCTAssertEqual(p.role("on\n"), "number")
    }

    /// A Haskell hex float (`0x1.8p3`, HexFloatLiterals) is one number.
    func testHaskellHexFloat() {
        let p = paintTier("x = 0x1.8p3\n", .haskell)
        XCTAssertEqual(p.wholeRole("0x1.8p3"), "number")
    }

    /// Move's spec builtin `global<T>(a)` is a call; the `std::signer` module is not the `signer` type.
    func testMoveGlobalAndSigner() {
        let p = paintTier(
            "module 0x1::m {\n    fun f(s: &signer): address { std::signer::address_of(s) }\n    spec f { ensures global<C>(@0x1).v == 1; }\n}\n",
            .move)
        XCTAssertEqual(p.role("global"), "function")
        XCTAssertEqual(p.role("signer"), "type")
        XCTAssertNotEqual(p.role("signer", 2), "type")
    }

    /// In a Nushell record a key is a name and a bare value a bare-word string; a signature's types stay types.
    func testNushellRecordKeysAndBareValues() {
        let p = paintTier("let r = {name: reload, qty: 12}\ndef f [x: int, y: string] { $x }\n", .nushell)
        XCTAssertEqual(p.role("name"), "property")
        XCTAssertEqual(p.role("{name"), "plain")
        XCTAssertEqual(p.role("reload"), "string")
        XCTAssertEqual(p.role("qty"), "property")
        XCTAssertEqual(p.role("12"), "number")
        XCTAssertEqual(p.role("string"), "type")
    }

    /// Only the `)` that closes a Razor `@( … )` is the transition's keyword, not one inside it.
    func testRazorExplicitExpressionCloser() {
        let p = paintTier("<button onclick=\"@(e => Hover(e))\">x</button>\n<p>@(count + 1)</p>\n", .razor)
        XCTAssertEqual(p.role(")"), "plain")
        XCTAssertEqual(p.role(")", 2), "keyword")
        XCTAssertEqual(p.role(")", 3), "keyword")
    }

    /// The regex Markdown tier paints a reference link and a footnote label as links (the tree-sitter tier does);
    /// a Quarto citation is a link too; a task box stays plain.
    func testMarkdownReferenceLinksFootnotesAndCitations() {
        let p = paintTier("See [the guide][ref] and a note.[^note] and [-@smith2020].\n\n- [x] done\n", .quarto)
        XCTAssertEqual(p.role("the guide"), "type")
        XCTAssertEqual(p.role("[ref]"), "type")
        XCTAssertEqual(p.role("^note"), "type")
        XCTAssertEqual(p.role("[-@smith2020]"), "type")
        XCTAssertEqual(p.role("x]"), "plain")
    }

    /// Inside `{literal}` braces are text, and a page's `<script>` is JavaScript: its numbers and comments.
    func testSmartyLiteralAndScript() {
        let p = paintTier("{literal}\n<script>\n// note {a: 1}\nvar o = {b: 2};\n</script>\n{/literal}\n{$x}\n", .smarty)
        XCTAssertEqual(p.role("// note"), "comment")
        XCTAssertEqual(p.role("{b"), "plain")
        XCTAssertEqual(p.role("2"), "number")
        XCTAssertEqual(p.role("literal"), "keyword")
        XCTAssertEqual(p.role("{$x}"), "keyword")
    }

    /// An SML type expression's names are types; a record field's label and the value a `val` names are not.
    func testSMLTypeExpressions() {
        let p = paintTier("sig\n  val add : sku * int -> t\nend\ntype item = { label : string }\n", .sml)
        XCTAssertEqual(p.role("sku"), "type")
        XCTAssertEqual(p.role("int"), "type")
        XCTAssertNotEqual(p.role("add"), "type")
        XCTAssertNotEqual(p.role("label"), "type")
        XCTAssertEqual(p.role("string"), "type")
    }

    /// The content of a Velocity `#[[ … ]]#` block is literal text.
    func testVelocityUnparsedContentIsText() {
        let p = paintTier("#[[ #set($x = 1) ]]#\n#set($y = 2)\n", .velocity)
        XCTAssertEqual(p.role("#set"), "plain")
        XCTAssertEqual(p.role("$x"), "plain")
        XCTAssertEqual(p.role("1"), "plain")
        XCTAssertEqual(p.role("#set", 2), "keyword")
        XCTAssertEqual(p.role("2"), "number")
    }

    /// Elixir's and Crystal's `#` before `{` opens an interpolation, which is code from its `#`; a `#` comment
    /// is still a comment.
    func testElixirAndCrystalInterpolationHash() {
        for language in [CodeLanguage.Language.elixir, .crystal] {
            let p = paintTier("x = \"a #{b} c\" # note\n", language)
            XCTAssertEqual(p.role("a "), "string", "\(language)")
            XCTAssertEqual(p.role("#{"), "plain", "\(language)")
            XCTAssertEqual(p.role("# note"), "comment", "\(language)")
        }
    }
}

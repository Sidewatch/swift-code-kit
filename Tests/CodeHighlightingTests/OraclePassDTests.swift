//
//  OraclePassDTests.swift
//  CodeHighlightingTests
//
//  The template and markup languages checked against the reference highlighters: each snippet is
//  the smallest piece of a showcase that the whole-file check found painted wrong.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

/// Smarty, Velocity, Marko, ERB, the Jinja family, MediaWiki, Twig, Blade, Liquid, Handlebars, DOT,
/// reStructuredText, Haml, Pug, Slim, CFML, LaTeX, BibTeX, Org, JSP, Razor, AsciiDoc and MDX: a
/// construct each, painted the way VS Code's grammar (or Pygments) reads it.
@MainActor
final class OraclePassDTests: XCTestCase {
    nonisolated private static let kinds: [TokenKind] = [
        .comment, .string, .keyword, .type, .number, .function, .attribute, .variable, .property, .added, .removed,
    ]

    private struct OneColourPerKind: TokenColorProviding {
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor {
            if kind == .identifier { return foreground }  // plain names read as plain text here
            let index = OraclePassDTests.kinds.firstIndex(of: kind) ?? 0
            return NSColor(srgbRed: CGFloat(index + 1) / 16, green: 0.5, blue: 0.25, alpha: 1)
        }
    }

    /// The kind every character of the `occurrence`-th `marker` in `text` is painted; nil when plain or
    /// mixed.
    private func kind(of marker: String, in text: String, _ language: Language, occurrence: Int = 1) -> TokenKind? {
        let colours = OneColourPerKind()
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colours.foreground])
        SyntaxHighlighter(language: language, colors: colours).highlight(storage, in: NSRange(location: 0, length: storage.length))
        let ns = text as NSString
        var range = NSRange(location: 0, length: 0)
        var from = 0
        for _ in 0..<occurrence {
            range = ns.range(of: marker, range: NSRange(location: from, length: ns.length - from))
            guard range.location != NSNotFound else { break }
            from = NSMaxRange(range)
        }
        XCTAssertNotEqual(range.location, NSNotFound, "marker \(marker) missing")
        guard range.location != NSNotFound else { return nil }
        let found = Set(
            (range.location..<NSMaxRange(range)).map { storage.attribute(.foregroundColor, at: $0, effectiveRange: nil) as? NSColor })
        guard found.count == 1, let colour = found.first ?? nil else { return nil }
        return Self.kinds.first { colours.color(for: $0) == colour }
    }

    /// Whether every character of the `occurrence`-th `marker` keeps the foreground.
    private func isPlain(_ marker: String, in text: String, _ language: Language, occurrence: Int = 1) -> Bool {
        let colours = OneColourPerKind()
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colours.foreground])
        SyntaxHighlighter(language: language, colors: colours).highlight(storage, in: NSRange(location: 0, length: storage.length))
        let ns = text as NSString
        var range = NSRange(location: 0, length: 0)
        var from = 0
        for _ in 0..<occurrence {
            range = ns.range(of: marker, range: NSRange(location: from, length: ns.length - from))
            guard range.location != NSNotFound else { return false }
            from = NSMaxRange(range)
        }
        return (range.location..<NSMaxRange(range)).allSatisfy {
            storage.attribute(.foregroundColor, at: $0, effectiveRange: nil) as? NSColor == colours.foreground
        }
    }

    // MARK: Smarty

    func testSmartyFunctionTagsAreFunctionsAndControlTagsKeywords() {
        let text = "{assign var=\"n\" value=1}{include file=\"a.tpl\"}{/include}\n{foreach $items as $item}{/foreach}{nocache}{/nocache}\n"
        XCTAssertEqual(kind(of: "assign", in: text, .smarty), .function)
        XCTAssertEqual(kind(of: "/include", in: text, .smarty), .function)
        XCTAssertEqual(kind(of: "foreach", in: text, .smarty), .keyword)
        XCTAssertEqual(kind(of: "nocache", in: text, .smarty), .keyword)
    }

    // MARK: Velocity

    func testVelocityMacroNamesAreFunctions() {
        let text = "#macro(badge $text)<b>$text</b>#end\n#badge(\"x\")\n#{badge}(\"y\")\n"
        XCTAssertEqual(kind(of: "badge", in: text, .velocity), .function)
        XCTAssertEqual(kind(of: "#badge", in: text, .velocity), .function)
        XCTAssertEqual(kind(of: "#{badge}", in: text, .velocity), .function)
    }

    func testVelocityAttributeValueWithDirectivesStaysPlainAroundThem() {
        let text = "<tr class=\"#if($low)low#{else}ok#end\">\n#set($ml = \"multi\nline\")\n"
        XCTAssertEqual(kind(of: "low", in: text, .velocity, occurrence: 2), nil)
        XCTAssertEqual(kind(of: "line\"", in: text, .velocity), .string)
    }

    // MARK: Marko

    func testMarkoTemplateLiteralHolesStayCode() {
        let text = "<const/greeting=`Hello ${input.name} again`/>\n"
        XCTAssertEqual(kind(of: "`Hello ", in: text, .marko), .string)
        XCTAssertEqual(kind(of: "input", in: text, .marko), nil)
        XCTAssertEqual(kind(of: " again`", in: text, .marko), .string)
    }

    func testMarkoHtmlCommentTextTypesArrowsAndStyleUnits() {
        let text = """
            export interface Input { list: Array<string> }
            <html-comment>kept in output</html-comment>
            $ const f = (o) => o;
            style.less { .a { color: red; width: 10%; opacity: .15; } }
            <![CDATA[ raw ${x} ]]>
            ${/regex/.test("x")}

            """
        XCTAssertEqual(kind(of: "Input", in: text, .marko), .type)
        XCTAssertEqual(kind(of: "Array", in: text, .marko), .type)
        XCTAssertEqual(kind(of: "kept in output", in: text, .marko), .comment)
        XCTAssertEqual(kind(of: "=>", in: text, .marko), .keyword)
        XCTAssertEqual(kind(of: ".less", in: text, .marko), .keyword)
        XCTAssertEqual(kind(of: "%", in: text, .marko), .keyword)
        XCTAssertEqual(kind(of: ".15", in: text, .marko), .number)
        XCTAssertEqual(kind(of: " raw ${x} ", in: text, .marko), .string)
        XCTAssertEqual(kind(of: "/regex/", in: text, .marko), .string)
    }

    // MARK: ERB, HAML

    func testRubyInterpolationStaysCode() {
        let erb = "<%= \"Hello #{user.name} there\" %>\n"
        XCTAssertEqual(kind(of: "\"Hello ", in: erb, .erb), .string)
        XCTAssertEqual(kind(of: "user", in: erb, .erb), nil)
        XCTAssertEqual(kind(of: " there\"", in: erb, .erb), .string)
        let haml = "%p= \"Hello #{user.name} there\"\n"
        XCTAssertNotEqual(kind(of: "user", in: haml, .haml), .string)
        XCTAssertEqual(kind(of: " there\"", in: haml, .haml), .string)
    }

    func testHamlRubyLinesAndPipedText() {
        let haml = "- begin\n  - items = %w[a b c]\n- rescue\n%p\n  | Piped \"text\" line\n"
        XCTAssertEqual(kind(of: "begin", in: haml, .haml), .keyword)
        XCTAssertEqual(kind(of: "rescue", in: haml, .haml), .keyword)
        XCTAssertEqual(kind(of: "%w[a b c]", in: haml, .haml), .string)
        XCTAssertTrue(isPlain("Piped", in: haml, .haml))
        let pug = "p\n  | Piped text line\n"
        XCTAssertTrue(isPlain("Piped text line", in: pug, .pug))
    }

    // MARK: Jinja, Nunjucks, Twig, Liquid, Handlebars

    func testTemplateTagWords() {
        XCTAssertEqual(kind(of: "debug", in: "{% debug %}\n", .jinja), .keyword)
        XCTAssertEqual(kind(of: "endverbatim", in: "{% verbatim %}{{ x }}{% endverbatim %}\n", .nunjucks), .keyword)
    }

    func testTemplateAttributeValueAroundTags() {
        let twig = "<input type=\"{{ type }}\" class=\"row-{{ i }} big\">\n"
        XCTAssertEqual(kind(of: "\"", in: twig, .twig), .string)
        XCTAssertEqual(kind(of: "\"row-", in: twig, .twig), .string)
        XCTAssertEqual(kind(of: " big\"", in: twig, .twig), .string)
        XCTAssertEqual(kind(of: "type", in: twig, .twig, occurrence: 2), nil)
    }

    func testTemplateAttributeValueQuoteAfterATagClosesIt() {
        let hbs = "<a class=\"{{classes}}\">{{label}}</a>\n"
        XCTAssertEqual(kind(of: ">", in: hbs, .handlebars), .keyword)
    }

    func testTemplateLiteralClosingBacktickOpensNoLiteral() {
        let text = "<const/greeting=`Hello ${input.name}`/>\n<let/counter=0/>\n<p>`code`</p>\n"
        XCTAssertNotEqual(kind(of: "/>", in: text, .marko), .string)
        XCTAssertNotEqual(kind(of: "<let", in: text, .marko), .string)
    }

    func testTemplateTagStringMayHoldClosingBraces() {
        let hbs = "{{helper \"a }} b\" 'with {{ braces'}}\n"
        XCTAssertEqual(kind(of: "'with {{ braces'", in: hbs, .handlebars), .string)
    }

    func testLiquidCommentTagsAndNumbers() {
        let text = "{% doc %}\n  @param {Product} product\n{% enddoc %}\n{%- # inline note -%}\n{{ 1.5e3 }}\n"
        XCTAssertNotEqual(kind(of: "doc", in: text, .liquid), .comment)
        XCTAssertEqual(kind(of: "@param {Product} product", in: text, .liquid), .comment)
        XCTAssertEqual(kind(of: "# inline note", in: text, .liquid), .comment)
        XCTAssertEqual(kind(of: "{%-", in: text, .liquid, occurrence: 1), .keyword)
        XCTAssertEqual(kind(of: "1.5", in: text, .liquid), .number)
    }

    func testPageScriptAndStyleInTemplates() {
        let hbs = "<script>\n  const title = \"{{title}}\";\n</script>\n"
        XCTAssertEqual(kind(of: "const", in: hbs, .handlebars), .keyword)
        XCTAssertEqual(kind(of: "\"{{title}}\"", in: hbs, .handlebars), .string)
        let cfm = "<style>\n  .low { color: #c00; padding: .25rem; }\n</style>\n"
        XCTAssertEqual(kind(of: ".low", in: cfm, .cfml), .type)
        XCTAssertEqual(kind(of: "#c00", in: cfm, .cfml), .number)
        XCTAssertEqual(kind(of: "rem", in: cfm, .cfml), .keyword)
    }

    // MARK: MediaWiki, Blade

    func testMediaWikiEmbeddedBlocks() {
        let text = """
            <templatedata>{"description": "Template data"}</templatedata>
            <syntaxhighlight lang="bash">
            echo "done"
            </syntaxhighlight>
            <syntaxhighlight lang="js" inline>const x = 1;</syntaxhighlight>

            """
        XCTAssertEqual(kind(of: "\"Template data\"", in: text, .mediawiki), .string)
        XCTAssertEqual(kind(of: "\"description\"", in: text, .mediawiki), .property)
        XCTAssertEqual(kind(of: "\"done\"", in: text, .mediawiki), .string)
        XCTAssertEqual(kind(of: "const", in: text, .mediawiki), .keyword)
        XCTAssertEqual(kind(of: "1", in: text, .mediawiki), .number)
    }

    func testBladePlainPhpTagIsCode() {
        XCTAssertEqual(kind(of: "'php tag'", in: "<?php $legacy = strtoupper('php tag'); ?>\n", .blade), .string)
    }

    // MARK: DOT

    func testDotQuotedIdsAreNamesAndValuesStrings() {
        let text = "digraph \"pipeline\" {\n  \"quoted node\" -> b [label = \"edge\", penwidth = 2.];\n  c [label = <<B>bold</B>>];\n}\n"
        XCTAssertEqual(kind(of: "\"pipeline\"", in: text, .dot), .variable)
        XCTAssertEqual(kind(of: "\"quoted node\"", in: text, .dot), .variable)
        XCTAssertEqual(kind(of: "\"edge\"", in: text, .dot), .string)
        XCTAssertEqual(kind(of: "2.", in: text, .dot), .number)
        XCTAssertEqual(kind(of: "<B", in: text, .dot), .keyword)
        XCTAssertTrue(isPlain("bold", in: text, .dot))
    }

    // MARK: reStructuredText

    func testRestructuredTextRules() {
        let text = """
            .. |version| replace:: 1.4.0

            See https://example.com and **strong ``literal`` text** and ``mono``.

            =====  =====
            a      b
            =====  =====

            .. code:: json

               {"qty": 25}

            """
        XCTAssertEqual(kind(of: "replace::", in: text, .restructuredtext), .keyword)
        XCTAssertTrue(isPlain("https://example.com", in: text, .restructuredtext))
        XCTAssertNotEqual(kind(of: "``literal``", in: text, .restructuredtext), .string)
        XCTAssertEqual(kind(of: "``mono``", in: text, .restructuredtext), .string)
        XCTAssertEqual(kind(of: "=====  =====", in: text, .restructuredtext), .keyword)
        XCTAssertEqual(kind(of: "25", in: text, .restructuredtext), .number)
    }

    // MARK: Slim

    func testSlimQuotesOpenStringsOnlyWhereValuesStart() {
        let text = """
            p text with "quotes" inside
            a href=link_to("x") title="Orders"
            - begin
            = render "row", count: 3
            p= number_with_delimiter(12_345)
            | Piped "text"
            p Escaped #{"<b>x</b>"}

            """
        XCTAssertTrue(isPlain("\"quotes\"", in: text, .slim))
        XCTAssertEqual(kind(of: "\"x\"", in: text, .slim), .string)
        XCTAssertEqual(kind(of: "\"Orders\"", in: text, .slim), .string)
        XCTAssertEqual(kind(of: "begin", in: text, .slim), .keyword)
        XCTAssertEqual(kind(of: "count", in: text, .slim), .string)
        XCTAssertEqual(kind(of: "12_345", in: text, .slim), .number)
        XCTAssertTrue(isPlain("\"text\"", in: text, .slim))
        XCTAssertEqual(kind(of: "\"<b>x</b>\"", in: text, .slim), .string)
    }

    // MARK: CFML

    func testCFMLCallsTypesAndNumbers() {
        let text =
            "<cfset obj = local.query.len()>\n<p>#timeFormat(now(), \"HH\")#</p>\n<cfscript>\nthrow(type = \"X\");\nnums = [0x1F];\n</cfscript>\n"
        XCTAssertEqual(kind(of: "timeFormat", in: text, .cfml), .function)
        XCTAssertEqual(kind(of: "throw", in: text, .cfml), .function)
        XCTAssertNotEqual(kind(of: "query", in: text, .cfml), .type)
        XCTAssertEqual(kind(of: "0", in: text, .cfml, occurrence: 1), .number)
    }

    // MARK: LaTeX

    func testLaTeXMathDelimitersAndControlSymbols() {
        let text =
            "Inline $E = mc^2$, \\(a^2\\) and \\[ x \\] line\\\\[3pt] thin\\,space \\newcommand*{\\x}{y}\n\\[\\begin{matrix}1\\\\3\\end{matrix}\\]\n"
        XCTAssertEqual(kind(of: "$", in: text, .latex), .string)
        XCTAssertTrue(isPlain("E", in: text, .latex))
        XCTAssertEqual(kind(of: "\\(", in: text, .latex), .string)
        XCTAssertEqual(kind(of: "\\\\", in: text, .latex), .keyword)
        XCTAssertEqual(kind(of: "\\,", in: text, .latex), .keyword)
        XCTAssertEqual(kind(of: "*", in: text, .latex), .keyword)
        XCTAssertEqual(kind(of: "3", in: text, .latex, occurrence: 2), .number)
    }

    // MARK: BibTeX

    func testBibTeXValuesCommentsAndJunk() {
        let text = """
            @book{key,
              note    = {Reprinted in \\emph{Classics}, \\acme},
              title   = "A \\"quoted\\" title",
              author  = {A. Author} # " and " # {B. Writer}
            }
            @comment{
              ignored text
            }
            junk text between entries

            """
        XCTAssertEqual(kind(of: "{Reprinted in \\emph{Classics}, \\acme}", in: text, .bibtex), .string)
        XCTAssertTrue(isPlain("quoted\\", in: text, .bibtex))
        XCTAssertNotEqual(kind(of: "#", in: text, .bibtex), .string)
        XCTAssertEqual(kind(of: "ignored text", in: text, .bibtex), .comment)
        XCTAssertEqual(kind(of: "junk text between entries", in: text, .bibtex), .comment)
    }

    // MARK: Org

    func testOrgIndentedStarBulletAndTables() {
        let text = "* Heading\n  * Indented bullet\n| Key | Value |\n"
        XCTAssertEqual(kind(of: "*", in: text, .org, occurrence: 2), .keyword)
        XCTAssertEqual(kind(of: "| Key | Value |", in: text, .org), .string)
    }

    // MARK: JSP

    func testJSPAttributeValues() {
        let text = "<tr class=\"${row.size < 10 ? 'low' : 'ok'}\">\n<jsp:param name=\"year\" value=\"<%= year %>\" />\n"
        XCTAssertEqual(kind(of: "\"${row.size < 10 ? 'low' : 'ok'}\"", in: text, .jsp), .string)
        XCTAssertEqual(kind(of: "<%=", in: text, .jsp), .keyword)
        XCTAssertEqual(kind(of: "\"", in: text, .jsp, occurrence: 5), .string)
    }

    // MARK: Razor

    func testRazorDirectivesAndCodeBlocks() {
        let text = """
            @model OrdersModel
            @using Inventory.Web
            @addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers
            @functions {
                private string Label(Order o) => $"#{o.Number} ({o.Status})";
            }
            <p>@Model.Orders.Count(x => x.IsPaid) user@@example.com</p>
            <tr class="@(paid ? "paid" : "open")" data-id="@order.Id">
            @switch (status)
            {
                case "paid":
                    <b>Paid</b>
                    break;
            }
            @code {
                [Parameter] public RenderFragment<Order>? Row { get; set; }
                private Task Load() => Task.CompletedTask;
            }

            """
        XCTAssertEqual(kind(of: "OrdersModel", in: text, .razor), .type)
        XCTAssertEqual(kind(of: "Inventory", in: text, .razor), .type)
        XCTAssertEqual(kind(of: "*, Microsoft.AspNetCore.Mvc.TagHelpers", in: text, .razor), .string)
        XCTAssertEqual(kind(of: "{", in: text, .razor), .keyword)
        XCTAssertEqual(kind(of: "$\"#", in: text, .razor), .string)
        XCTAssertNotEqual(kind(of: "Number", in: text, .razor), .string)
        XCTAssertEqual(kind(of: " (", in: text, .razor, occurrence: 1), .string)
        XCTAssertEqual(kind(of: "Count", in: text, .razor), .function)
        XCTAssertEqual(kind(of: "@@", in: text, .razor), .string)
        XCTAssertNotEqual(kind(of: "paid ?", in: text, .razor), .string)
        XCTAssertEqual(kind(of: "case", in: text, .razor), .keyword)
        XCTAssertEqual(kind(of: "break", in: text, .razor), .keyword)
        XCTAssertEqual(kind(of: "Parameter", in: text, .razor), .type)
        XCTAssertEqual(kind(of: "Order", in: "@code {\n    public RenderFragment<Order>? Row { get; set; }\n}\n", .razor), .type)
        XCTAssertEqual(kind(of: "Task", in: text, .razor), .type)
    }

    // MARK: AsciiDoc

    func testAsciiDocEntriesMacrosAndDelimiters() {
        let text = """
            :toc: left
            [abstract]
            Press kbd:[Ctrl+C] or btn:[Save], see <<intro,the intro>> and footnote:[A note.].
            Visit https://example.com[Example site] today.
            Escaped \\footnote:[skipped] text.
            NOTE: A note.
            ====
            Inside.
            ====
            "`curved`" and `mono`.
            {counter:step:1}

            """
        XCTAssertEqual(kind(of: "left", in: text, .asciidoc), .string)
        XCTAssertEqual(kind(of: "abstract", in: text, .asciidoc), .function)
        XCTAssertEqual(kind(of: "kbd:", in: text, .asciidoc), .function)
        XCTAssertEqual(kind(of: "Ctrl+C", in: text, .asciidoc), .string)
        XCTAssertTrue(isPlain("[", in: text, .asciidoc, occurrence: 2))
        XCTAssertEqual(kind(of: "the intro", in: text, .asciidoc), .string)
        XCTAssertEqual(kind(of: "A note.", in: text, .asciidoc), .string)
        XCTAssertEqual(kind(of: "Example site", in: text, .asciidoc), .string)
        XCTAssertTrue(isPlain("skipped", in: text, .asciidoc))
        XCTAssertEqual(kind(of: "NOTE:", in: text, .asciidoc), .function)
        XCTAssertEqual(kind(of: "====", in: text, .asciidoc), .keyword)
        XCTAssertNotEqual(kind(of: "`curved`", in: text, .asciidoc), .string)
        XCTAssertEqual(kind(of: "`mono`", in: text, .asciidoc), .string)
        XCTAssertEqual(kind(of: "1}", in: text, .asciidoc), nil)
        XCTAssertEqual(kind(of: "1", in: text, .asciidoc, occurrence: 1), .string)
    }

    // MARK: Mermaid

    func testMermaidStructureWordsNodeShapesAndMessages() {
        let text = """
            %%{init: {"theme": "neutral"}}%%
            flowchart TB
                direction LR
                A[Receive goods] --> B{Inspect?}
            sequenceDiagram
                U->>W: Request list

            """
        XCTAssertEqual(kind(of: "direction", in: text, .mermaid), .keyword)
        XCTAssertEqual(kind(of: "[", in: text, .mermaid), .keyword)
        XCTAssertEqual(kind(of: "Receive goods", in: text, .mermaid), .string)
        XCTAssertEqual(kind(of: "{", in: text, .mermaid, occurrence: 3), .keyword)
        XCTAssertNotEqual(kind(of: ":", in: text, .mermaid, occurrence: 2), .string)
        XCTAssertEqual(kind(of: "Request list", in: text, .mermaid), .string)
    }

    // MARK: MDX

    func testMDXFrontMatterLinksAndFences() {
        let text = """
            ---
            title: Stock handbook
            reorder: 25
            tags: [inventory, "cli"]
            ---

            1. Read [the docs](https://example.com "Docs") and &copy; &#169;.

            ```bash
            npm install -g pkg
            ```

            ```js title="a.js"
            const n = await fetch(`/api/${id}?q`);
            ```

            Text ~~gone~~ here.

            """
        XCTAssertEqual(kind(of: "---", in: text, .mdx), .string)
        XCTAssertEqual(kind(of: "title", in: text, .mdx), .property)
        XCTAssertEqual(kind(of: " Stock handbook", in: text, .mdx), .string)
        XCTAssertEqual(kind(of: "25", in: text, .mdx), .number)
        XCTAssertEqual(kind(of: "inventory", in: text, .mdx), .string)
        XCTAssertEqual(kind(of: "1", in: text, .mdx, occurrence: 1), .string)
        XCTAssertEqual(kind(of: "[", in: text, .mdx, occurrence: 2), .string)
        XCTAssertEqual(kind(of: "](https://example.com \"Docs\")", in: text, .mdx), .string)
        XCTAssertEqual(kind(of: "copy", in: text, .mdx), .keyword)
        XCTAssertEqual(kind(of: "169", in: text, .mdx), .number)
        XCTAssertEqual(kind(of: "bash", in: text, .mdx), .function)
        XCTAssertEqual(kind(of: "npm", in: text, .mdx), .function)
        XCTAssertEqual(kind(of: " install", in: text, .mdx), .string)
        XCTAssertNotEqual(kind(of: "\"a.js\"", in: text, .mdx), .string)
        XCTAssertEqual(kind(of: "const", in: text, .mdx), .keyword)
        XCTAssertEqual(kind(of: "fetch", in: text, .mdx), .function)
        XCTAssertEqual(kind(of: "`/api/", in: text, .mdx), .string)
        XCTAssertNotEqual(kind(of: "id", in: text, .mdx, occurrence: 1), .string)
        XCTAssertEqual(kind(of: "~~", in: text, .mdx), .string)
        XCTAssertTrue(isPlain("gone", in: text, .mdx))
    }

    func testMDXJavaScriptInExpressionsAndESM() {
        let text = """
            export const Table = ({ rows }) => rows.length;
            export async function load(id) { return 1; }

            Count: {stockRows.map((r) => r * 2)} and {/ab+c/gi.test("x")}.

            <Chart period="ytd" data={[1, 2]} />

            """
        XCTAssertEqual(kind(of: "Table", in: text, .mdx), .function)
        XCTAssertEqual(kind(of: "load", in: text, .mdx), .function)
        XCTAssertEqual(kind(of: "n", in: "export const big = 10n;\n", .mdx, occurrence: 2), .keyword)
        XCTAssertEqual(kind(of: "map", in: text, .mdx), .function)
        XCTAssertEqual(kind(of: "2", in: text, .mdx), .number)
        XCTAssertEqual(kind(of: "/ab+c/", in: text, .mdx), .string)
        XCTAssertEqual(kind(of: "gi", in: text, .mdx), .keyword)
        XCTAssertEqual(kind(of: "\"ytd\"", in: text, .mdx), .string)
    }
}

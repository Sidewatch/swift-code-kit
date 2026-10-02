//
//  WholeFileBatch4Tests.swift
//  CodeHighlightingTests
//
//  Pascal, SPARQL, Turtle and the template languages: each showcase coloured correctly from its first
//  line to its last.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

/// Each snippet is the smallest thing from a corpus showcase that the regex tier painted wrong; the
/// test reads back the role painted on the first character of a marker.
@MainActor
final class WholeFileBatch4Tests: XCTestCase {
    /// One distinct colour per role, so the role at a position reads back exactly.
    private struct OneColourPerRole: TokenColorProviding {
        static let kinds: [TokenKind] = [.comment, .string, .keyword, .type, .number, .function, .attribute, .variable, .property]
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor {
            let index = Self.kinds.firstIndex(of: kind) ?? Self.kinds.count
            return NSColor(srgbRed: CGFloat(index + 1) / 16, green: 0.5, blue: 0.25, alpha: 1)
        }
    }

    /// The role painted on the first character of the `occurrence`-th `marker` in `text`, or nil when
    /// it stays the default foreground.
    private func role(of marker: String, occurrence: Int = 1, in text: String, _ language: Language) -> TokenKind? {
        let colors = OneColourPerRole()
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colors.foreground])
        SyntaxHighlighter(language: language, colors: colors).highlight(storage, in: NSRange(location: 0, length: storage.length))
        let ns = text as NSString
        var at = NSRange(location: 0, length: 0)
        for _ in 0..<occurrence {
            at = ns.range(of: marker, range: NSRange(location: NSMaxRange(at), length: ns.length - NSMaxRange(at)))
            XCTAssertNotEqual(at.location, NSNotFound, "no \(marker) in the snippet")
            if at.location == NSNotFound { return nil }
        }
        let colour = storage.attribute(.foregroundColor, at: at.location, effectiveRange: nil) as? NSColor
        return OneColourPerRole.kinds.first { colors.color(for: $0) == colour }
    }

    // MARK: Pascal

    func testPascalSingleQuotedStringIsAString() {
        XCTAssertEqual(role(of: "inner", in: "begin\n  WriteLn('inner');\nend;\n", .pascal), .string)
    }

    func testPascalDoubledQuoteStaysInsideTheString() {
        let text = "S := 'It''s a \"test\"';\nX := 1;\n"
        XCTAssertEqual(role(of: "test", in: text, .pascal), .string)
        XCTAssertEqual(role(of: "X", in: text, .pascal), nil)
    }

    func testPascalBraceInsideAStringIsNoComment() {
        XCTAssertEqual(role(of: "8F1E", in: "  ['{8F1E5C2A-3B4D}']\n  function F: string;\n", .pascal), .string)
    }

    func testPascalMultiLineStringRunsToItsClosingTripleQuote() {
        let text = "const\n  M = '''\n    A Delphi multi-line string.\n    ''';\n  N = 1;\n"
        XCTAssertEqual(role(of: "Delphi", in: text, .pascal), .string)
        XCTAssertEqual(role(of: "N =", in: text, .pascal), nil)
    }

    func testPascalPrefixedNumbersAndCharCodes() {
        let text = "H := $FF + %1010 + &17;\nS := 'a' + #9;\n"
        XCTAssertEqual(role(of: "$FF", in: text, .pascal), .number)
        XCTAssertEqual(role(of: "%1010", in: text, .pascal), .number)
        XCTAssertEqual(role(of: "#9", in: text, .pascal), .string)
    }

    func testPascalReservedWordsInAnyCase() {
        XCTAssertEqual(role(of: "BEGIN", in: "BEGIN\n  x := 1\nEND.\n", .pascal), .keyword)
        XCTAssertEqual(role(of: "procedure", in: "procedure Run; virtual;\n", .pascal), .keyword)
    }

    // MARK: Every pattern compiles

    /// `SyntaxHighlighter` skips a pattern that does not compile, silently — an unbounded repeat inside a
    /// look back is enough — so a table can lose a rule with nothing failing.
    func testEveryPatternOfTheseTablesCompiles() {
        let languages: [Language] = [
            .pascal, .sparql, .turtle, .jinja, .twig, .nunjucks, .liquid, .handlebars, .smarty, .velocity, .erb, .jsp, .cfml, .razor,
            .marko, .blade, .raku, .pug, .haml, .slim, .vimscript, .vue, .svelte, .astro,
        ]
        for language in languages {
            for (pattern, _) in RuleTables.table(for: language) {
                XCTAssertNoThrow(try NSRegularExpression(pattern: pattern, options: .anchorsMatchLines), "\(language): \(pattern)")
            }
        }
    }

    // MARK: SPARQL and Turtle

    func testSPARQLDoubleQuotedLiteralIsAString() {
        XCTAssertEqual(role(of: "anonymous", in: "[] ex:note \"anonymous subject\" .\n", .sparql), .string)
    }

    func testSPARQLHashInsideAnIRIOpensNoComment() {
        let text = "PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>\nSELECT ?x WHERE { ?x a ?t }\n"
        XCTAssertNotEqual(role(of: "#>", in: text, .sparql), .comment)
        XCTAssertEqual(role(of: "# real", in: "?s ?p ?o . # real comment\n", .sparql), .comment)
    }

    func testSPARQLHashInsideAStringOpensNoComment() {
        let text = "BIND (STRAFTER(STR(?type), \"#\") AS ?kind)\n"
        XCTAssertEqual(role(of: "AS", in: text, .sparql), .keyword)
    }

    func testSPARQLTripleQuotedLiteralSpansLines() {
        XCTAssertEqual(role(of: "double", in: "?s ex:p \"\"\"triple\ndouble quoted\"\"\" .\n", .sparql), .string)
    }

    func testTurtleHashInsideAnIRIOpensNoComment() {
        let text = "@prefix ex: <https://example.com/schema#> .\nex:Item a ex:Thing .\n"
        XCTAssertNotEqual(role(of: "#>", in: text, .turtle), .comment)
        XCTAssertNotEqual(role(of: "ex:Item", in: text, .turtle), .comment)
    }

    // MARK: Jinja, Twig, Nunjucks

    func testTwigEscapedQuoteDoesNotEndTheString() {
        let text = "{% set single = 'it\\'s single quoted' %}\n{# NOTE a comment #}\n{% set a = 'first' %}\n"
        XCTAssertEqual(role(of: "NOTE", in: text, .twig), .comment)
        XCTAssertEqual(role(of: "first", in: text, .twig), .string)
    }

    func testTwigQuotesInsideAnAttributeTagAreStringsAndTheTagIsCode() {
        let text = "<tr class=\"{{ low ? 'low' : 'ok' }}\">\n<td colspan=\"6\">{{ item.qty }}</td>\n"
        XCTAssertEqual(role(of: "'low'", in: text, .twig), .string)
        XCTAssertNotEqual(role(of: "? ", in: text, .twig), .string)
        XCTAssertEqual(role(of: "\"6\"", in: text, .twig), .string)
    }

    func testJinjaQuotesBetweenTagsAreTheDocumentsNotStrings() {
        let text = "mode: \"0644\"\nsrc: \"{{ role_path }}/app.conf\"\n"
        XCTAssertNotEqual(role(of: "0644", in: text, .jinja), .string)
        XCTAssertNotEqual(role(of: "role_path", in: text, .jinja), .string)
    }

    func testJinjaEscapedQuoteAndMultiLineLiteral() {
        let text = "{{ '\\'' }} {{ x }}\n{{ \"multi\nline literal\" }}\n{# NOTE #}\n"
        XCTAssertNotEqual(role(of: "x }}", in: text, .jinja), .string)
        XCTAssertEqual(role(of: "line literal", in: text, .jinja), .string)
        XCTAssertEqual(role(of: "NOTE", in: text, .jinja), .comment)
    }

    func testJinjaTagWordsInProseStayPlain() {
        let text = "<p>Nothing in stock</p>\n{% for x in xs %}{% endfor %}\n"
        XCTAssertNil(role(of: "in stock", in: text, .jinja))
        XCTAssertEqual(role(of: "in xs", in: text, .jinja), .keyword)
    }

    func testNunjucksEscapedQuoteAndMultiLineTag() {
        let text = "{{ 'it\\'s' }} {{ x }} {{ 'y' }}\n{%\n  set m = {\n    \"a\": 1\n  }\n%}\n<p class=\"muted\">it's</p>\n"
        XCTAssertNotEqual(role(of: "x }}", in: text, .nunjucks), .string)
        XCTAssertEqual(role(of: "\"a\"", in: text, .nunjucks), .string)
        XCTAssertEqual(role(of: "\"muted\"", in: text, .nunjucks), .string)
    }

    func testTurtleLongStringHoldsQuotesAndEndsAtItsClosingTripleQuote() {
        let text = ":e ex:long \"\"\"A long string that\nspans lines with \"quotes\" freely.\"\"\" ;\n    ex:n 7 .\n"
        XCTAssertEqual(role(of: "quotes", in: text, .turtle), .string)
        XCTAssertEqual(role(of: "7", in: text, .turtle), .number)
    }

    // MARK: Liquid, Handlebars, Smarty, Velocity

    func testLiquidStringHasNoEscapesAndBlockCommentsAreComments() {
        let text = #"{% assign p = "C:\" %}{{ x }}"# + "\n{% comment %}\n  NOTE hidden\n{% endcomment %}\n{% if a %}{% endif %}\n"
        XCTAssertNotEqual(role(of: "x }}", in: text, .liquid), .string)
        XCTAssertEqual(role(of: "NOTE", in: text, .liquid), .comment)
        XCTAssertEqual(role(of: "if a", in: text, .liquid), .keyword)
    }

    func testLiquidTagWordsAndNumbersOnlyInsideTags() {
        let text = "<p>Sold in 3 days</p>\n{% for p in products limit: 3 %}{% endfor %}\n"
        XCTAssertNil(role(of: "in 3", in: text, .liquid))
        XCTAssertEqual(role(of: "3 %}", in: text, .liquid), .number)
    }

    func testHandlebarsShortCommentAndBracedStringStayInBounds() {
        let text =
            "{{! NOTE short comment }}\n{{helper \"with }} braces\" 'and {{ braces'}}\n{{helper 1 true}}\n{{!-- ── Partials ── --}}\n"
        XCTAssertEqual(role(of: "NOTE", in: text, .handlebars), .comment)
        XCTAssertEqual(role(of: "Partials", in: text, .handlebars), .comment)
        XCTAssertEqual(role(of: "true", in: text, .handlebars), .number)
    }

    func testSmartyLiteralsInsideATagButNotInABraceWithASpace() {
        let text = "{assign var=\"n\" value=12}\n<style>.x { width: 40px; }</style>\n{if $a == true}{/if}\n"
        XCTAssertEqual(role(of: "12", in: text, .smarty), .number)
        XCTAssertNil(role(of: "40", in: text, .smarty))
        XCTAssertEqual(role(of: "true", in: text, .smarty), .number)
        XCTAssertEqual(role(of: "if $a", in: text, .smarty), .keyword)
    }

    func testVelocityNumbersInArgumentsAndMultiLineStrings() {
        let text = "#set($n = 25)\n#set($s = \"multi\nline string\")\n<p>Page 2</p>\n"
        XCTAssertEqual(role(of: "25", in: text, .velocity), .number)
        XCTAssertEqual(role(of: "line string", in: text, .velocity), .string)
        XCTAssertNil(role(of: "2<", in: text, .velocity))
    }

    // MARK: ERB, JSP, CFML, Razor, Marko, Blade

    func testERBRubyCommentsAndKeywordsInsideScriptlets() {
        let text = "<%\n  # NOTE ruby comment\n  total = 0 if x\n=begin\nblock\n=end\n%>\n<p>if you like</p>\n"
        XCTAssertEqual(role(of: "NOTE", in: text, .erb), .comment)
        XCTAssertEqual(role(of: "block", in: text, .erb), .comment)
        XCTAssertEqual(role(of: "if x", in: text, .erb), .keyword)
        XCTAssertNil(role(of: "if you", in: text, .erb))
    }

    func testJSPJavaCommentsInScriptletsAndELStrings() {
        let text = "<%\n  // NOTE java comment\n  int year = 2026;\n%>\n<p>${'single \\'escaped\\''} ${x}</p>\n"
        XCTAssertEqual(role(of: "NOTE", in: text, .jsp), .comment)
        XCTAssertEqual(role(of: "int", in: text, .jsp), .type)
        XCTAssertNotEqual(role(of: "x}", in: text, .jsp), .string)
    }

    func testCFMLNestedCommentAndScriptComments() {
        let text =
            "<!---\n  <!--- inner --->\n  NOTE still a comment\n--->\n<cfscript>\n  // NOTE2 script\n  b = 7;  // NOTE3 trailing\n</cfscript>\n<p>for http://example.com</p>\n"
        XCTAssertEqual(role(of: "NOTE still", in: text, .cfml), .comment)
        XCTAssertEqual(role(of: "NOTE2", in: text, .cfml), .comment)
        XCTAssertEqual(role(of: "NOTE3", in: text, .cfml), .comment)
        XCTAssertNil(role(of: "for http", in: text, .cfml))
    }

    func testRazorCodeBlockKeywordsAndComments() {
        let text = "@code {\n    // NOTE csharp comment\n    private int count = 1;\n}\n<p>Mail support@example.com for help</p>\n"
        XCTAssertEqual(role(of: "NOTE", in: text, .razor), .comment)
        XCTAssertEqual(role(of: "private", in: text, .razor), .keyword)
        XCTAssertEqual(role(of: "int", in: text, .razor), .type)
        XCTAssertNil(role(of: "for help", in: text, .razor))
        XCTAssertNotEqual(role(of: "example.com", in: text, .razor), .variable)
    }

    func testMarkoLineCommentsButNotAURL() {
        let text = "// NOTE a comment\n<a href=x>see http://example.com/a</a>\n$ const n = 1;\n"
        XCTAssertEqual(role(of: "NOTE", in: text, .marko), .comment)
        XCTAssertNotEqual(role(of: "example", in: text, .marko), .comment)
        XCTAssertEqual(role(of: "const", in: text, .marko), .keyword)
    }

    func testBladeBoundAttributeIsCodeAndEchoStringsAreStrings() {
        let text = "<x-alert :message=\"$message\" class=\"mb-4\">\n<a href=\"{{ route('home') }}\">Home</a>\n"
        XCTAssertNotEqual(role(of: "$message", in: text, .blade), .string)
        XCTAssertEqual(role(of: "\"mb-4\"", in: text, .blade), .string)
        XCTAssertEqual(role(of: "'home'", in: text, .blade), .string)
        XCTAssertNotEqual(role(of: "route", in: text, .blade), .string)
    }

    // MARK: Raku

    func testRakuPodBlockIsAComment() {
        let text = "=begin pod\n=head1 Inventory\nsay \"code in pod\";\n=end pod\nsay 1;\n"
        XCTAssertEqual(role(of: "Inventory", in: text, .raku), .comment)
        XCTAssertEqual(role(of: "code in pod", in: text, .raku), .comment)
    }

    func testRakuPackageNameIsNoSymbolAndQuotingFormsAreStrings() {
        let text = "need Cro::HTTP::Client;\nmy $q = q[no interpolation $here];\nmy $h = q:to/END/;\n    heredoc body\n    END\nsay 1;\n"
        XCTAssertNotEqual(role(of: "HTTP", in: text, .raku), .string)
        XCTAssertEqual(role(of: "no interpolation", in: text, .raku), .string)
        XCTAssertEqual(role(of: "heredoc body", in: text, .raku), .string)
    }

    func testRakuHyperOperatorOpensNoGuillemetString() {
        let text = "say (1, 2) »+« (3, 4), -« (1, 2);\nmy $x = 5;\nmy $w = «alpha beta»;\n"
        XCTAssertNotEqual(role(of: "my $x", in: text, .raku), .string)
        XCTAssertEqual(role(of: "alpha", in: text, .raku), .string)
    }

    // MARK: Pug, Haml, Slim

    func testPugBlockCommentCoversItsIndentedLines() {
        let text = "//-\n  NOTE an unbuffered block comment\np Text\n"
        XCTAssertEqual(role(of: "NOTE", in: text, .pug), .comment)
        XCTAssertNotEqual(role(of: "Text", in: text, .pug), .comment)
    }

    func testHamlConditionalCommentLeavesNestedMarkupRendered() {
        let text = "/\n  NOTE block html comment\n/[if IE]\n  %p Rendered\n"
        XCTAssertEqual(role(of: "NOTE", in: text, .haml), .comment)
        XCTAssertNotEqual(role(of: "Rendered", in: text, .haml), .comment)
    }

    func testSlimSlashInTextIsNoCommentAndApostropheEndsOnItsLine() {
        let text = "p Mixed <em>inline</em> and more text\np it's here\np = render partial: \"row\", as: :item\n"
        XCTAssertNotEqual(role(of: "more text", in: text, .slim), .comment)
        XCTAssertNotEqual(role(of: "render", in: text, .slim), .string)
        XCTAssertEqual(role(of: ":item", in: text, .slim), .string)
    }

    func testPugApostropheInTextDoesNotPairAcrossLines() {
        let text = "p it's here\nif ready\np don't\n"
        XCTAssertEqual(role(of: "if ready", in: text, .pug), .keyword)
    }

    // MARK: Vim script, Vue, Astro

    func testVimSubstitutionAndCatchPatternsAreStrings() {
        let text = "%s/\\<teh\\>/the/ge\ntry\ncatch /^stock-/\nendtry\n"
        XCTAssertEqual(role(of: "teh", in: text, .vimscript), .string)
        XCTAssertEqual(role(of: "stock-", in: text, .vimscript), .string)
    }

    func testVueDirectiveValueIsCodeAndItsClosingQuoteOpensNothing() {
        let text = "<p v-if=\"count > 5\" class=\"muted\">x</p>\n<p @click=\"go\">y</p>\n"
        XCTAssertNotEqual(role(of: "count", in: text, .vue), .string)
        XCTAssertEqual(role(of: "\"muted\"", in: text, .vue), .string)
        XCTAssertNotEqual(role(of: "go", in: text, .vue), .string)
    }

    func testAstroSlashesInBodyTextAreTextButCommentInsideAnExpression() {
        let text = "<p>see https://example.com</p>\n// NOTE text in the body\n{\n  // NOTE2 in an expression\n  label\n}\n"
        XCTAssertNotEqual(role(of: "NOTE text", in: text, .astro), .comment)
        XCTAssertEqual(role(of: "NOTE2", in: text, .astro), .comment)
    }
}

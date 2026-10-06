//
//  WholeFileBatch3Tests.swift
//  CodeHighlightingTests
//
//  The whole-file pass over the shells, the stylesheets and the other batch-3 showcases: each rule
//  table paints its language's real keywords, strings, comments and numbers from first line to last.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

/// Each snippet is the smallest thing from a corpus showcase the old table painted wrong; the test
/// reads back the role the regex tier gives one marker in it.
@MainActor
final class WholeFileBatch3Tests: XCTestCase {
    private struct OneColourPerKind: TokenColorProviding {
        static let kinds: [TokenKind] = [.comment, .string, .keyword, .type, .number, .function, .attribute, .variable, .property]
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor {
            if kind == .identifier { return foreground }  // plain names read as plain text here
            return NSColor(srgbRed: CGFloat((Self.kinds.firstIndex(of: kind) ?? 0) + 1) / 16, green: 0.5, blue: 0.25, alpha: 1)
        }
    }

    /// The role of the first character of the `occurrence`-th `marker` in `text`, or nil when it is plain.
    private func kind(_ marker: String, in text: String, _ language: Language, occurrence: Int = 1) -> TokenKind? {
        let colors = OneColourPerKind()
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colors.foreground])
        SyntaxHighlighter(language: language, colors: colors).highlight(storage, in: NSRange(location: 0, length: storage.length))
        let ns = text as NSString
        var at = NSRange(location: 0, length: 0)
        for _ in 0..<occurrence {
            at = ns.range(of: marker, range: NSRange(location: NSMaxRange(at), length: ns.length - NSMaxRange(at)))
        }
        guard at.location != NSNotFound, let color = storage.attribute(.foregroundColor, at: at.location, effectiveRange: nil) as? NSColor
        else { return nil }
        return OneColourPerKind.kinds.first { colors.color(for: $0) == color }
    }

    // MARK: Shells

    func testShellHeredocBodyAndDelimiterAreString() {
        let text = "cat <<EOF\nRegion: $REGION in here\nEOF\necho done\n"
        for language in [Language.sh, .zsh] {
            XCTAssertEqual(kind("Region", in: text, language), .string)
            XCTAssertEqual(kind("EOF", in: text, language, occurrence: 2), .string)
            XCTAssertEqual(kind("echo", in: text, language), .function)
        }
    }

    func testShellHashInsideParameterExpansionIsNotAComment() {
        let text = "print ${file##*/} ${#file} done\n"
        XCTAssertNotEqual(kind("done", in: text, .zsh), .comment)
        XCTAssertEqual(kind("# real", in: "x=1 # real\n", .zsh), .comment)
    }

    func testShellAnsiCQuotingIsOneString() {
        let text = "ansi=$'tab\\there \\'quoted\\''\n# after\n"
        XCTAssertEqual(kind("quoted", in: text, .sh), .string)
        XCTAssertEqual(kind("# after", in: text, .sh), .comment)
    }

    func testShellQuotesInsideCommandSubstitutionStayInTheString() {
        let text = "nested=\"$(echo \"$(basename \"$PWD\")\")\"\n# after\n"
        XCTAssertNotEqual(kind("basename", in: text, .sh), .string, "a command substitution is code")
        XCTAssertEqual(kind("# after", in: text, .sh), .comment)
    }

    // MARK: Declaration languages

    func testBicepDeclarationKeywordsAndDirectives() {
        let text =
            "param prefix string = 'acme'\nresource vault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {}\n#disable-next-line no-unused-params\n"
        XCTAssertEqual(kind("param", in: text, .bicep), .keyword)
        XCTAssertEqual(kind("resource", in: text, .bicep), .keyword)
        XCTAssertEqual(kind("existing", in: text, .bicep), .keyword)
        XCTAssertEqual(kind("no-unused", in: text, .bicep), .keyword)
        XCTAssertEqual(kind("if", in: "var x = if (cond) {}\n", .bicep), .keyword)
    }

    func testCarbonReservedWordsAndSizedTypes() {
        let text = "fn Add(a: i32, b: i32) -> i32 { if (a > 0) { return a; } }\nchoice Shape { Circle }\n"
        XCTAssertEqual(kind("i32", in: text, .carbon), .type)
        XCTAssertEqual(kind("choice", in: text, .carbon), .keyword)
        XCTAssertEqual(kind("if", in: text, .carbon), .keyword)
        XCTAssertEqual(kind("raw", in: "let s: String = #\"raw \\n\"#;\n", .carbon), .string)
    }

    func testDKeywordsTypesAndStringForms() {
        let text = "immutable int x = 1;\nforeach (i; 0 .. 3) {}\nauto s = q\"(nested (x) y)\";\nauto t = q{auto y = 2;};\n"
        XCTAssertEqual(kind("immutable", in: text, .d), .keyword)
        XCTAssertEqual(kind("int", in: text, .d), .type)
        XCTAssertEqual(kind("foreach", in: text, .d), .keyword)
        XCTAssertEqual(kind("y)", in: text, .d), .string)
        XCTAssertEqual(kind("auto y", in: text, .d), .keyword, "a q{…} token string holds tokens, painted as code")
    }

    func testSolidityKeywordsBeforeParentheses() {
        let text = "function f() external payable returns (uint256) { require(ok, \"no\"); }\nmapping(address => uint) m;\n"
        XCTAssertEqual(kind("function", in: text, .solidity), .keyword)
        XCTAssertEqual(kind("returns", in: text, .solidity), .keyword)
        XCTAssertEqual(kind("require", in: text, .solidity), .keyword)
        XCTAssertEqual(kind("mapping", in: text, .solidity), .keyword)
        XCTAssertEqual(kind("uint256", in: text, .solidity), .type)
    }

    func testVHDLReservedWordsAnyCaseAndBitStrings() {
        let text = "signal flags : std_logic_vector(3 DOWNTO 0) := X\"F\";\nconstant S : string := \"done\";\n"
        XCTAssertEqual(kind("signal", in: text, .vhdl), .keyword)
        XCTAssertEqual(kind("DOWNTO", in: text, .vhdl), .keyword)
        XCTAssertEqual(kind("X\"F\"", in: text, .vhdl), .number)
        XCTAssertEqual(kind("done", in: text, .vhdl), .string)
        XCTAssertEqual(kind("constant", in: text, .vhdl), .keyword)
    }

    func testCrystalStringsHeredocsPercentLiteralsAndRegexes() {
        let text =
            "a = \"x #{\"nested #{b}\"} y\"\nh = <<-TEXT\n  body\n  TEXT\np = %w(one two)\nr = /^A-\\d+$/i\ninclude JSON::Serializable\nmacro m; end\n"
        XCTAssertEqual(kind("y\"", in: text, .crystal), .string)
        XCTAssertEqual(kind("body", in: text, .crystal), .string)
        XCTAssertEqual(kind("two", in: text, .crystal), .string)
        XCTAssertEqual(kind("^A", in: text, .crystal), .string)
        XCTAssertNotEqual(kind("Serializable", in: text, .crystal), .string)
        XCTAssertEqual(kind("macro", in: text, .crystal), .keyword)
    }

    func testErlangFunCallsAndCharacterLiterals() {
        let text = "F = fun(X) -> X end,\nC = [$\\x41, $\\n],\nN = 16#DEAD_beef.\n"
        XCTAssertEqual(kind("fun", in: text, .erlang), .keyword)
        XCTAssertEqual(kind("x41", in: text, .erlang), .number)
        XCTAssertEqual(kind("DEAD", in: text, .erlang), .number)
    }

    func testDotGraphWordsAnyCaseAndUnquotedValues() {
        let text = "digraph g {\n  node [shape = box];\n  NODE [color = red];\n}\n"
        XCTAssertEqual(kind("node", in: text, .dot), .keyword)
        XCTAssertEqual(kind("NODE", in: text, .dot), .keyword)
        XCTAssertEqual(kind("box", in: text, .dot), .string)
    }

    // MARK: Stylesheets

    func testStylesheetUnquotedURLOpensNoComment() {
        let text = "@namespace svg url(http://www.w3.org/2000/svg);\n.a { color: red; }\n"
        for language in [Language.scss, .postcss, .stylus] {
            XCTAssertEqual(kind("http", in: text, language), .string)
            XCTAssertNotEqual(kind("www", in: text, language), .comment)
        }
    }

    /// A unit wears the type colour beside its number, as the CSS grammar's `(unit) @type` paints it.
    func testStylesheetNumbersKeepPercentAndLeadingDot() {
        let text = ".a { width: 100%; opacity: .5; }\n"
        XCTAssertEqual(kind("100", in: text, .scss), .number)
        XCTAssertEqual(kind("%", in: text, .scss), .type)
        XCTAssertEqual(kind(".5", in: text, .scss), .number)
    }

    func testPostCSSAndStylusAtRulesAndControlWords() {
        XCTAssertEqual(kind("@define-mixin", in: "@define-mixin icon $name {}\n", .postcss), .keyword)
        XCTAssertEqual(kind("@media", in: "@media (min-width: 30em) {}\n", .postcss), .keyword)
        let stylus = "for name in sizes\n  if v is defined\n    display none\n"
        XCTAssertEqual(kind("in", in: stylus, .stylus), .keyword)
        XCTAssertEqual(kind("if", in: stylus, .stylus), .keyword)
        XCTAssertEqual(kind("defined", in: stylus, .stylus), .keyword)
    }

    func testSCSSControlWordsAfterEachAndFor() {
        let text = "@each $name in $list {}\n@for $i from 1 through 3 {}\n"
        XCTAssertEqual(kind("in", in: text, .scss), .keyword)
        XCTAssertEqual(kind("through", in: text, .scss), .keyword)
    }

    // MARK: Command and task languages

    func testBatchCommentsStringsAndVariables() {
        let text = ":: a comment\ncopy /y \"%ROOT%a.txt\" \"%DROP%\\\"\necho rem is not a comment ^& done\nREM real\nset /a n=%%~nF\n"
        XCTAssertEqual(kind(":: a", in: text, .batch), .comment)
        XCTAssertEqual(kind("REM real", in: text, .batch), .comment)
        XCTAssertNotEqual(kind("rem is", in: text, .batch), .comment)
        XCTAssertNotEqual(kind("echo rem", in: text, .batch), .string)
        XCTAssertEqual(kind("echo", in: text, .batch), .keyword)
        XCTAssertEqual(kind("%%~nF", in: text, .batch), .type)
    }

    func testJustInterpolationQuotesStayInTheString() {
        let text = "build:\n    echo \"{{ if os() == \"macos\" { \"mac\" } else { \"other\" } }}\"\nunexport DEBUG\n"
        XCTAssertEqual(kind("macos", in: text, .just), .string)
        XCTAssertEqual(kind("other", in: text, .just), .string)
        XCTAssertEqual(kind("unexport", in: text, .just), .keyword)
        XCTAssertEqual(kind("build", in: text, .just), .function)
    }

    func testNushellRawStringsInterpolationAndKeywords() {
        let text = "let raw = r#'raw with \"quotes\" and # hash'#\nlet s = $\"total ($n | math round)\"\nlet p = ./data/orders.csv\n"
        XCTAssertNotEqual(kind("# hash", in: text, .nushell), .comment)
        XCTAssertEqual(kind("hash", in: text, .nushell), .string)
        XCTAssertEqual(kind("let", in: text, .nushell), .keyword)
        XCTAssertEqual(kind("round", in: text, .nushell), .string)
        XCTAssertEqual(kind("data", in: text, .nushell), .string)
    }

    func testPRQLStringsCommentsAndDurations() {
        let text = "let x = [\"double\", 'single', 3months]\n# a comment\nfrom orders\n"
        XCTAssertEqual(kind("double", in: text, .prql), .string)
        XCTAssertEqual(kind("# a", in: text, .prql), .comment)
        XCTAssertEqual(kind("3months", in: text, .prql), .number)
        XCTAssertEqual(kind("let", in: text, .prql), .keyword)
    }

    func testNginxRegexIsAStringNotATag() {
        let text = "server {\n    server_name ~^(?<sub>.+)\\.example\\.net$;\n    location ~* \\.(css|js)$ { expires 1y; }\n}\n"
        XCTAssertEqual(kind("(?<sub", in: text, .nginx), .string)
        XCTAssertEqual(kind("\\.(css", in: text, .nginx), .string)
        XCTAssertEqual(kind("location", in: text, .nginx), .keyword)
        XCTAssertEqual(kind("expires", in: text, .nginx), .keyword)
    }

    // MARK: Markup and query languages

    func testOrgCommentBlockBodyIsAComment() {
        let text = "#+begin_comment\nNever exported.\n#+end_comment\nProse.\n"
        XCTAssertEqual(kind("Never", in: text, .org), .comment)
        XCTAssertNotEqual(kind("Prose", in: text, .org), .comment)
    }

    func testXQueryNestedCommentsAndVariables() {
        let text = "(: outer (: inner :) still comment :)\nlet $sliding := 1 return $x\n"
        XCTAssertEqual(kind("still", in: text, .xquery), .comment)
        XCTAssertEqual(kind("sliding", in: text, .xquery), .variable)
    }

    func testGettextPluralIndexIsANumber() {
        XCTAssertEqual(kind("1", in: "msgstr[1] \"x\"\n", .gettext), .number)
    }
}

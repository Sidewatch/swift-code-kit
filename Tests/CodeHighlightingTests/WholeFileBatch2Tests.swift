//
//  WholeFileBatch2Tests.swift
//  CodeHighlightingTests
//
//  Whole-file fixes for Stata, Hack, properties, Jsonnet, Cypher, Move, Cap'n Proto, VB.NET, R, OCaml,
//  Standard ML, Gleam, GDScript, Thrift, Wolfram, BibTeX, CoffeeScript, LaTeX, Markdown, MDX, AsciiDoc and
//  reStructuredText: each snippet is the smallest piece of the language's showcase that was painted wrong.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

/// Each test names a token in a snippet and the role it must be painted in (or must not be painted in).
@MainActor
final class WholeFileBatch2Tests: XCTestCase {
    /// One distinct colour per role, so a painted colour reads back as its role.
    private struct OneColourPerRole: TokenColorProviding {
        static let roles: [TokenKind] = [
            .comment, .string, .keyword, .type, .number, .function, .attribute, .variable, .property, .added, .removed,
        ]
        let foreground = NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        func color(for kind: TokenKind) -> NSColor {
            let index = Self.roles.firstIndex(of: kind) ?? 0
            return NSColor(srgbRed: CGFloat(index + 1) / 16, green: 0.5, blue: 0.5, alpha: 1)
        }
    }

    /// The role painted on the first character of `token` in `text`, or nil where it is left plain.
    private func role(of token: String, in text: String, _ language: Language) -> TokenKind? {
        let colours = OneColourPerRole()
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colours.foreground])
        SyntaxHighlighter(language: language, colors: colours).highlight(storage, in: NSRange(location: 0, length: storage.length))
        let at = (text as NSString).range(of: token).location
        XCTAssertNotEqual(at, NSNotFound, "\(token) is not in the snippet")
        guard at != NSNotFound, let colour = storage.attribute(.foregroundColor, at: at, effectiveRange: nil) as? NSColor else {
            return nil
        }
        return OneColourPerRole.roles.first { colours.color(for: $0) == colour }
    }

    // MARK: Stata

    func testStataLocalMacroQuoteOpensNoString() {
        let text = "local first : word 1 of `varlist'\n* NOTE a comment line\nlocal second `varlist'\n"
        XCTAssertEqual(role(of: "NOTE", in: text, .stata), .comment)
    }

    func testStataCommandsAreKeywords() {
        XCTAssertEqual(role(of: "display", in: "display \"hello\"\n", .stata), .keyword)
    }

    // MARK: Hack

    func testHackIndentedHeredocIsOneString() {
        let text = "function f(): void {\n  $h = <<<EOT\n  Heredoc BODY with $int\n  EOT;\n  $after = 1;\n}\n"
        XCTAssertEqual(role(of: "BODY", in: text, .hack), .string)
        XCTAssertNotEqual(role(of: "$after", in: text, .hack), .string)
    }

    func testHackNowdocIsOneString() {
        let text = "$n = <<<'EOT'\nNowdoc BODY\nEOT;\n"
        XCTAssertEqual(role(of: "BODY", in: text, .hack), .string)
    }

    // MARK: Properties

    func testPropertiesEscapedHashInAKeyOpensNoComment() {
        let text = "key\\#not\\!comment=4\n\\#escaped.hash.start=5\n# a comment\n"
        XCTAssertNotEqual(role(of: "not", in: text, .properties), .comment)
        XCTAssertNotEqual(role(of: "escaped", in: text, .properties), .comment)
        XCTAssertEqual(role(of: "a comment", in: text, .properties), .comment)
    }

    // MARK: Jsonnet

    func testJsonnetHashCommentAndTextBlock() {
        let text = "# hash comment\nlocal block = |||\n  Text BODY\n|||;\n"
        XCTAssertEqual(role(of: "hash", in: text, .jsonnet), .comment)
        XCTAssertEqual(role(of: "BODY", in: text, .jsonnet), .string)
        XCTAssertEqual(role(of: "local", in: text, .jsonnet), .keyword)
    }

    // MARK: Cypher

    func testCypherDoubleDashIsARelationshipNotAComment() {
        let text = "MATCH (e)--(f) RETURN e;\n"
        XCTAssertEqual(role(of: "RETURN", in: text, .cypher), .keyword)
    }

    func testCypherEscapedQuoteDoesNotEndTheString() {
        let text = "RETURN 'it\\'s' AS s // NOTE trailing\nRETURN 'x'\n"
        XCTAssertEqual(role(of: "NOTE", in: text, .cypher), .comment)
    }

    // MARK: Move

    func testMoveLoopLabelOpensNoString() {
        let text = "loop { break 'outer; }\n// NOTE a comment\nlet x = 'a;\n"
        XCTAssertEqual(role(of: "NOTE", in: text, .move), .comment)
        XCTAssertEqual(role(of: "fun", in: "public fun f() {}\n", .move), .keyword)
    }

    // MARK: Cap'n Proto

    func testCapnpAnnotationIsAKeyword() {
        XCTAssertEqual(role(of: "annotation", in: "annotation foo(struct) :Text;\n", .capnp), .keyword)
    }

    // MARK: VB.NET

    func testVBNetDirectivesAndDateLiteralsAreNotComments() {
        let text = "#If DEBUG Then\nDim dt As Date = #3/1/2026 9:30:00 AM#\n#End If\n"
        XCTAssertNotEqual(role(of: "#If", in: text, .vbnet), .comment)
        XCTAssertNotEqual(role(of: "#3/1", in: text, .vbnet), .comment)
        XCTAssertEqual(role(of: "Dim", in: text, .vbnet), .keyword)
    }

    // MARK: R

    func testRNamespaceAccessIsNotASymbolString() {
        let text = "dplyr::filter\nstats:::internal_function\n"
        XCTAssertNotEqual(role(of: "filter", in: text, .r), .string)
        XCTAssertNotEqual(role(of: "internal_function", in: text, .r), .string)
    }

    func testRFunctionIsAKeyword() {
        XCTAssertEqual(role(of: "function", in: "f <- function(x) x\n", .r), .keyword)
    }

    // MARK: OCaml and Standard ML

    func testOCamlCharacterLiteralsAreStrings() {
        let text = "let f = function 'a' .. 'z' -> 1 | _ -> 0\n"
        XCTAssertEqual(role(of: "'a'", in: text, .ocaml), .string)
        XCTAssertEqual(role(of: "'z'", in: text, .ocaml), .string)
    }

    func testOCamlTypeVariableOpensNoStringAndLoopsAreKeywords() {
        let text = "type 'a box = 'a list\nlet () = for i = 1 to 3 do ignore i done (* NOTE *)\n"
        XCTAssertEqual(role(of: "NOTE", in: text, .ocaml), .comment)
        XCTAssertNotEqual(role(of: "box", in: text, .ocaml), .string)
        XCTAssertEqual(role(of: "done", in: text, .ocaml), .keyword)
    }

    func testStandardMLCharacterLiteralAndKeywords() {
        let text = "val c = #\"a\"\nval f = fn x => x\n"
        XCTAssertEqual(role(of: "#\"a\"", in: text, .sml), .string)
        XCTAssertEqual(role(of: "fn", in: text, .sml), .keyword)
    }

    // MARK: Gleam, GDScript, Thrift, Wolfram

    func testGleamKeywords() {
        XCTAssertEqual(role(of: "pub", in: "pub fn main() { Nil }\n", .gleam), .keyword)
    }

    func testGDScriptKeywords() {
        let text = "var speed := 10\nfunc _ready() -> void:\n\tpass\n"
        XCTAssertEqual(role(of: "var", in: text, .gdscript), .keyword)
        XCTAssertEqual(role(of: "func", in: text, .gdscript), .keyword)
    }

    func testThriftBaseTypes() {
        XCTAssertEqual(role(of: "i32", in: "struct S { 1: required i32 id }\n", .thrift), .type)
    }

    func testWolframDecrementIsNotAComment() {
        let text = "incr = (i--; total);\n"
        XCTAssertNotEqual(role(of: "total", in: text, .wolfram), .comment)
    }

    // MARK: BibTeX and CoffeeScript

    func testBibTeXCommentEntryIsAComment() {
        let text = "@comment{\n  Multi-line comment BODY.\n  @article{not-an-entry, title = {ignored}}\n}\n@book{key, title = {T}}\n"
        XCTAssertEqual(role(of: "BODY", in: text, .bibtex), .comment)
        XCTAssertEqual(role(of: "not-an-entry", in: text, .bibtex), .comment)
        XCTAssertEqual(role(of: "@book", in: text, .bibtex), .keyword)
    }

    func testCoffeeScriptThreeLevelInterpolationEndsTheString() {
        let text = "x = \"a #{ \"b #{ \"c #{y}\" }\" }\" + tail\n"
        XCTAssertNotEqual(role(of: "tail", in: text, .coffeescript), .comment)
    }

    // MARK: LaTeX

    func testLaTeXEscapedPercentAndDollarOpenNothing() {
        let text = "Special characters: \\& \\% \\$ \\# and TAIL text.\n% NOTE a comment\n"
        XCTAssertNotEqual(role(of: "TAIL", in: text, .latex), .comment)
        XCTAssertNotEqual(role(of: "TAIL", in: text, .latex), .string)
        XCTAssertEqual(role(of: "NOTE", in: text, .latex), .comment)
    }

    // MARK: Markdown family (regex tier)

    func testTildeFenceIsCode() {
        let text = "~~~bash\necho BODY\n~~~\n\nafter\n"
        XCTAssertEqual(role(of: "BODY", in: text, .quarto), .string)
        XCTAssertNotEqual(role(of: "after", in: text, .quarto), .string)
    }

    func testDoubleBacktickCodeSpanHoldsABacktick() {
        let text = "`` a ` b `` then NOTE `c`\n"
        XCTAssertNotEqual(role(of: "NOTE", in: text, .quarto), .string)
    }

    func testMDXApostropheOpensNoString() {
        let text = "Revenue in {meta.author}'s words.\n\n## Heading\n\nAnd it's done.\n"
        XCTAssertNotEqual(role(of: "Heading", in: text, .mdx), .string)
        XCTAssertEqual(role(of: "Heading", in: text, .mdx), .keyword)
    }

    // MARK: AsciiDoc and reStructuredText

    func testAsciiDocParagraphUnderADelimiterIsNotAHeading() {
        let text = "[NOTE]\n====\nA delimited PARAGRAPH\n====\n"
        XCTAssertNotEqual(role(of: "PARAGRAPH", in: text, .asciidoc), .keyword)
    }

    func testReStructuredTextDirectiveIsNotACommentAndCommentsSpanTheirIndent() {
        let text = ".. meta::\n   :keywords: a, b\n\n.. A comment.\n   Indented CONTINUATION line.\n\n..\n   LATER comment body.\n"
        XCTAssertEqual(role(of: ".. meta", in: text, .restructuredtext), .keyword)
        XCTAssertEqual(role(of: "CONTINUATION", in: text, .restructuredtext), .comment)
        XCTAssertEqual(role(of: "LATER", in: text, .restructuredtext), .comment)
    }
}

//
//  WholeFileBatch5Tests.swift
//  CodeHighlightingTests
//
//  The whole-file pass over ActionScript to Zig: each language's own comments, strings and keywords.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

/// Each snippet is the smallest piece of a corpus showcase that a family table painted wrongly: a comment
/// form it did not know, a string that ran on or never started, a keyword it lacked. `kind(of:in:)` reads
/// back the role painted on the first character of the first occurrence of a token.
@MainActor
final class WholeFileBatch5Tests: XCTestCase {
    private struct OneColourPerKind: TokenColorProviding {
        static let kinds: [TokenKind] = [
            .comment, .string, .keyword, .type, .number, .function, .attribute, .variable, .property, .added, .removed,
        ]
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor {
            let index = Self.kinds.firstIndex(of: kind) ?? 0
            return NSColor(srgbRed: CGFloat(index + 1) / 16, green: 0.5, blue: 0.25, alpha: 1)
        }
    }

    /// The role painted on the first character of `token`'s first occurrence, or nil when it stays plain.
    private func kind(of token: String, in text: String, _ language: Language) -> TokenKind? {
        let colours = OneColourPerKind()
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colours.foreground])
        SyntaxHighlighter(language: language, colors: colours).highlight(storage, in: NSRange(location: 0, length: storage.length))
        let at = (text as NSString).range(of: token).location
        XCTAssertNotEqual(at, NSNotFound, "\(token) is not in the snippet")
        guard at != NSNotFound, let c = storage.attribute(.foregroundColor, at: at, effectiveRange: nil) as? NSColor else { return nil }
        return OneColourPerKind.kinds.first { colours.color(for: $0) == c }
    }

    // MARK: Comments

    func testAppleScriptHashCommentAndNestedBlockComment() {
        let text = "# hash NOTE\n(* outer (* inner *) still OUTER *)\nset x to 1\n"
        XCTAssertEqual(kind(of: "hash", in: text, .applescript), .comment)
        XCTAssertEqual(kind(of: "OUTER", in: text, .applescript), .comment)
        XCTAssertEqual(kind(of: "set", in: text, .applescript), .keyword)
    }

    func testIdrisMultiplicationSectionOpensNoComment() {
        let text = "||| doc line\ncombine = (*)\n\nuseIt : Nat\nuseIt = 2\n"
        XCTAssertEqual(kind(of: "doc", in: text, .idris), .comment)
        XCTAssertNotEqual(kind(of: "useIt", in: text, .idris), .comment)
    }

    func testPerlPODIsACommentAndLastIndexIsNot() {
        let text = "=pod\n\nsample POD text\n\n=cut\nmy $n = $#items + 1;\n"
        XCTAssertEqual(kind(of: "sample", in: text, .perl), .comment)
        XCTAssertNotEqual(kind(of: "items", in: text, .perl), .comment)
        XCTAssertEqual(kind(of: "my", in: text, .perl), .keyword)
    }

    func testTclHashIsACommentOnlyWhereACommandStarts() {
        let text = "uplevel #0 {set top 1}\nputs ok ;# trailing remark\n"
        XCTAssertNotEqual(kind(of: "set top", in: text, .tcl), .comment)
        XCTAssertEqual(kind(of: "trailing", in: text, .tcl), .comment)
        XCTAssertEqual(kind(of: "uplevel", in: text, .tcl), .keyword)
    }

    func testDotenvHashInsideAValueOpensNoComment() {
        let text = "HASH_NO_SPACE=value#notacomment\nexport KEY=1 # trailing\n"
        XCTAssertNotEqual(kind(of: "notacomment", in: text, .dotenv), .comment)
        XCTAssertEqual(kind(of: "trailing", in: text, .dotenv), .comment)
        XCTAssertEqual(kind(of: "export", in: text, .dotenv), .keyword)
    }

    func testApacheHashInsideAnArgumentOpensNoComment() {
        let text = "IndexIgnore .??* *~ *# HEADER* README*\n# a real comment\n"
        XCTAssertNotEqual(kind(of: "README", in: text, .apacheconf), .comment)
        XCTAssertEqual(kind(of: "real", in: text, .apacheconf), .comment)
    }

    func testGitCommitIssueReferenceIsNoComment() {
        let text = "Fix the filter\n\nFixes #142 and more text\n# Please enter the commit message\n"
        XCTAssertNotEqual(kind(of: "and more", in: text, .gitcommit), .comment)
        XCTAssertEqual(kind(of: "Please", in: text, .gitcommit), .comment)
    }

    func testKDLSlashdashCommentsOutANodeAndAnArgument() {
        let text = "/- disabled-node \"gone\"\nnode /- \"dropped\" kept\n"
        XCTAssertEqual(kind(of: "disabled", in: text, .kdl), .comment)
        XCTAssertEqual(kind(of: "dropped", in: text, .kdl), .comment)
        XCTAssertEqual(kind(of: "kept", in: text, .kdl), .string)
    }

    func testPLSQLRemarkLineIsAComment() {
        let text = "REM A SQL*Plus remark line\nSELECT 1 FROM dual;\n"
        XCTAssertEqual(kind(of: "remark", in: text, .plsql), .comment)
    }

    // MARK: Strings

    func testActionScriptRegularExpressionIsAString() {
        let text = "var re:RegExp = /(?P<year>\\d{4})-x/g;\nif (ok) {}\n"
        XCTAssertEqual(kind(of: "(?P", in: text, .actionscript), .string)
        XCTAssertEqual(kind(of: "if", in: text, .actionscript), .keyword)
    }

    func testHaxeTildeRegularExpressionIsAString() {
        let text = "var regex = ~/^[A-Z]{3}$/i;\nfunction f() {}\n"
        XCTAssertEqual(kind(of: "^[A-Z]", in: text, .haxe), .string)
        XCTAssertEqual(kind(of: "function", in: text, .haxe), .keyword)
    }

    func testAWKRegexWithAHashOpensNoComment() {
        let text = "/^#/ { next }\n$1 ~ /x/ { print $2 }\n"
        XCTAssertNotEqual(kind(of: "next", in: text, .awk), .comment)
        XCTAssertEqual(kind(of: "/^#/", in: text, .awk), .string)
        XCTAssertEqual(kind(of: "print", in: text, .awk), .keyword)
    }

    func testAdaCharacterLiteralAndAttributeTick() {
        let text = "Space : constant Character := ' ';\nN : Integer := Items'Length + 16#FF#;\n"
        XCTAssertEqual(kind(of: "' '", in: text, .ada), .string)
        XCTAssertNotEqual(kind(of: "'Length", in: text, .ada), .string)
        XCTAssertEqual(kind(of: "FF#", in: text, .ada), .number)
        XCTAssertEqual(kind(of: "constant", in: text, .ada), .keyword)
    }

    func testPerlQuoteLikeAndHereDocument() {
        let text = "use POSIX qw(floor ceil);\nmy $h = <<\"END\";\nbody text\nEND\nmy $x = 1;\n"
        XCTAssertEqual(kind(of: "floor", in: text, .perl), .string)
        XCTAssertEqual(kind(of: "body", in: text, .perl), .string)
        XCTAssertNotEqual(kind(of: "$x", in: text, .perl), .string)
    }

    func testZigMultilineStringLine() {
        let text = "const s =\n    \\\\Multiline string literal.\n;\npub fn main() void {}\n"
        XCTAssertEqual(kind(of: "Multiline", in: text, .zig), .string)
        XCTAssertEqual(kind(of: "pub", in: text, .zig), .keyword)
    }

    func testReasonQuotedStringAndSwitch() {
        let text = "let q = {js|quoted with \"quotes\"|js};\nlet f = x => switch (x) { | _ => 0 };\n"
        XCTAssertEqual(kind(of: "quoted", in: text, .reason), .string)
        XCTAssertEqual(kind(of: "switch", in: text, .reason), .keyword)
    }

    func testCUERawStringHoldsQuotes() {
        let text = "raw: #\"raw \"inner\" kept\"#\nn: 1\n"
        XCTAssertEqual(kind(of: "inner", in: text, .cue), .string)
    }

    func testCaddyfileBacktickStringAndDirective() {
        let text = "respond `backtick string with \"quotes\" inside`\n"
        XCTAssertEqual(kind(of: "backtick", in: text, .caddyfile), .string)
        XCTAssertEqual(kind(of: "inside", in: text, .caddyfile), .string)
        XCTAssertEqual(kind(of: "respond", in: text, .caddyfile), .keyword)
    }

    func testMediaWikiApostropheInProseOpensNoString() {
        let text = "<score>\\relative c' { c d }</score>\n<chem>H2O</chem>\nit's here\n"
        XCTAssertNotEqual(kind(of: "H2O", in: text, .mediawiki), .string)
    }

    func testHiveQLBackslashEscapedQuoteStaysInTheString() {
        let text = "SELECT 'single \\'escaped\\' tail' AS s1, \"double \\\" tail\" AS s2 FROM t;\n"
        XCTAssertEqual(kind(of: "tail", in: text, .hiveql), .string)
        XCTAssertNotEqual(kind(of: "s1", in: text, .hiveql), .string)
        XCTAssertEqual(kind(of: "double", in: text, .hiveql), .string)
    }

    func testPLSQLAlternativeQuoting() {
        let text = "c := q'[bracket-quoted with 'single' quotes]';\nv NUMBER;\n"
        XCTAssertEqual(kind(of: "single", in: text, .plsql), .string)
        XCTAssertNotEqual(kind(of: "v NUMBER", in: text, .plsql), .string)
    }

    func testPLpgSQLOneLineDollarQuoteIsAString() {
        let text = "SELECT $tag$tagged $$ inside$tag$, 1;\n"
        XCTAssertEqual(kind(of: "inside", in: text, .plpgsql), .string)
    }

    func testGraphQLBlockStringHoldsQuotes() {
        let text = "\"\"\"\nSupports \"quotes\" and more prose.\n\"\"\"\ntype Query { a: Int }\n"
        XCTAssertEqual(kind(of: "quotes", in: text, .graphql), .string)
        XCTAssertEqual(kind(of: "type", in: text, .graphql), .keyword)
    }

    // MARK: Keywords

    func testVyperDefIsAKeyword() {
        XCTAssertEqual(kind(of: "def", in: "@external\ndef total() -> uint256:\n    return 1\n", .vyper), .keyword)
    }

    func testVPrimitiveTypes() {
        XCTAssertEqual(kind(of: "int", in: "fn add(a int, b int) int {\n\treturn a + b\n}\n", .v), .type)
    }

    func testAgdaKeywordsAndReservedSymbols() {
        let text = "open import Data.Nat using (ℕ)\nid : ∀ {A : Set} → A → A\n"
        XCTAssertEqual(kind(of: "using", in: text, .agda), .keyword)
        XCTAssertEqual(kind(of: "∀", in: text, .agda), .keyword)
    }

    func testCOBOLDashedReservedWordStaysAKeyword() {
        let text = "           IF WS-QTY > 0\n              DISPLAY \"OK\"\n           END-IF.\n"
        XCTAssertEqual(kind(of: "END-IF", in: text, .cobol), .keyword)
    }

    func testLLVMAtomicOrderingIsAKeyword() {
        XCTAssertEqual(kind(of: "seq_cst", in: "  %v = load atomic i32, ptr %p seq_cst, align 4\n", .llvm), .keyword)
    }

    func testPrismaViewBlockIsAKeyword() {
        XCTAssertEqual(kind(of: "view", in: "view StockSummary {\n  sku String @unique\n}\n", .prisma), .keyword)
    }
}

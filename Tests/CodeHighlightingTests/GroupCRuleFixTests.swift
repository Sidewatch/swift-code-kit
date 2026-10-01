//
//  GroupCRuleFixTests.swift
//  CodeHighlightingTests
//
//  Julia, KDL, Lean, Makefile and Mermaid: a literal form that used to run a string past its end.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

/// Each snippet holds the smallest construct that leaked, then a comment line that must stay a comment.
@MainActor
final class GroupCRuleFixTests: XCTestCase {
    private struct OneColourPerKind: TokenColorProviding {
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor { kind == .comment ? .systemGreen : .systemRed }
    }

    /// Whether every visible character of `needle`'s line comes out comment-coloured.
    private func commentLinePainted(
        _ text: String, _ language: Language, line needle: String, file: StaticString = #filePath, line: UInt = #line
    ) {
        let storage = NSTextStorage(string: text + "\n", attributes: [.foregroundColor: NSColor.black])
        SyntaxHighlighter(language: language, colors: OneColourPerKind())
            .highlight(storage, in: NSRange(location: 0, length: storage.length))
        let ns = storage.string as NSString
        let found = ns.range(of: needle)
        XCTAssertNotEqual(found.location, NSNotFound, file: file, line: line)
        for i in found.location..<NSMaxRange(found) {
            let glyph = ns.substring(with: NSRange(location: i, length: 1))
            guard !glyph.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            XCTAssertEqual(
                storage.attribute(.foregroundColor, at: i, effectiveRange: nil) as? NSColor, .systemGreen,
                "offset \(i) of \(needle)", file: file, line: line)
        }
    }

    func testJuliaTransposeQuoteIsNotACharacterLiteral() {
        commentLinePainted("y = a'\n# note\nz = b'", .julia, line: "# note")
        commentLinePainted("c = '\\u00e9'\n# note\ns = \"\"\"\nx\n\"\"\"", .julia, line: "# note")
    }

    func testKDLRawStringEndsAtItsHashedQuote() {
        commentLinePainted("x #\"say \"hi\"#\n// note\ny \"b\"", .kdl, line: "// note")
    }

    func testLeanEscapedQuoteCharacterLiteralIsNotAStringStart() {
        commentLinePainted("def c := '\\\"'\n-- note\ndef d := \"x\"", .lean, line: "-- note")
    }

    func testMakefileEscapedQuoteDoesNotOpenAString() {
        commentLinePainted("CFLAGS += -DV=\\\"$(V)\\\"\n# note\nx := \"y\"", .makefile, line: "# note")
    }

    func testMermaidUnclosedBracketStopsAtTheLineEnd() {
        commentLinePainted("flowchart TD\n    A[unclosed\n    %% note\n    B[x]", .mermaid, line: "%% note")
    }
}

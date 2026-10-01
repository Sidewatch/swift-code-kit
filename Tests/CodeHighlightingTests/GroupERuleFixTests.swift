//
//  GroupERuleFixTests.swift
//  CodeHighlightingTests
//
//  RON, SCSS, Slim, SystemVerilog, Verilog and Vim script: a quote that is not a string delimiter
//  (or a string form the table did not know) no longer swallows the comment lines after it.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

@MainActor
final class GroupERuleFixTests: XCTestCase {
    private struct OneColourPerKind: TokenColorProviding {
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor { kind == .comment ? .systemGreen : .systemRed }
    }

    /// Whether the first line of `source` that starts with `marker` is wholly comment-coloured.
    private func lineIsComment(_ source: String, startingWith marker: String, _ language: Language) -> Bool {
        let storage = NSTextStorage(string: source + "\n", attributes: [.foregroundColor: NSColor.black])
        SyntaxHighlighter(language: language, colors: OneColourPerKind())
            .highlight(storage, in: NSRange(location: 0, length: storage.length))
        let ns = storage.string as NSString
        let line = ns.range(of: marker)
        XCTAssertNotEqual(line.location, NSNotFound)
        for i in line.location..<ns.length {
            let c = ns.character(at: i)
            if c == 10 { break }
            if storage.attribute(.foregroundColor, at: i, effectiveRange: nil) as? NSColor != .systemGreen { return false }
        }
        return true
    }

    func testRONRawStringWithHashesDoesNotLeak() {
        let source = "a: r##\"x \"# y\"##,\n// next\nb: \"z\""
        XCTAssertTrue(lineIsComment(source, startingWith: "// next", .ron))
    }

    func testRONNestedBlockCommentIsOneComment() {
        XCTAssertTrue(lineIsComment("/* a /* b */\n   c */\n// next", startingWith: "   c */", .ron))
    }

    func testSCSSInterpolationQuotesDoNotCloseTheString() {
        let source = "a { content: \"#{s.unquote(\"\\\"q\\\"\")} and #{t($r)}\"; }\n// next\nb { c: \"d\"; }"
        XCTAssertTrue(lineIsComment(source, startingWith: "// next", .scss))
    }

    func testSlimTextBlockQuoteDoesNotPairAcrossLines() {
        let source = "p\n  ' Text\n/ next\np\n  | 'x'"
        XCTAssertTrue(lineIsComment(source, startingWith: "/ next", .slim))
    }

    func testSystemVerilogBaseMarkerIsNotAString() {
        let source = "a = 8'hFF;\n// next\nb = 1'b1;"
        XCTAssertTrue(lineIsComment(source, startingWith: "// next", .systemverilog))
    }

    func testVerilogBaseMarkerIsNotAString() {
        let source = "assign a = 4'd9;\n// next\nassign b = 1'b0;"
        XCTAssertTrue(lineIsComment(source, startingWith: "// next", .verilog))
    }

    func testVimscriptStrayQuoteDoesNotRunOnToTheNextLine() {
        let source = "set viminfo='100,<50\n\" next\nlet a = 'x'"
        XCTAssertTrue(lineIsComment(source, startingWith: "\" next", .vimscript))
    }
}

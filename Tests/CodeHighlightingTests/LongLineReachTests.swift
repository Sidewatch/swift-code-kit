//
//  LongLineReachTests.swift
//  CodeHighlightingTests
//
//  A pass over a few characters of a huge line paints near them, not the whole line.
//
//  Created by David Sherlock on 10/10/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import CodeLanguage
import XCTest

@testable import CodeHighlighting

@MainActor
final class LongLineReachTests: XCTestCase {
    private struct Painter: TokenColorProviding {
        func color(for kind: TokenKind) -> NSColor { .red }
        var foreground: NSColor { .blue }
    }

    func testAPassOverAFewCharactersOfAHugeLinePaintsOnlyNearThem() {
        let line = String(repeating: "K=v ", count: 500_000)  // one 2 MB line
        let storage = NSTextStorage(string: "x\n" + line + "\ny", attributes: [.foregroundColor: NSColor.black])
        let at = 1_000_000
        SyntaxHighlighter(language: .dotenv, colors: Painter()).highlight(storage, in: NSRange(location: at, length: 100))
        func painted(_ i: Int) -> Bool { (storage.attribute(.foregroundColor, at: i, effectiveRange: nil) as? NSColor) != .black }
        XCTAssertTrue(painted(at), "the asked range is painted")
        XCTAssertTrue(
            painted(at - SyntaxHighlighter.lineReach + 1) && painted(at + 99 + SyntaxHighlighter.lineReach - 1),
            "the reach counts from the last asked character")
        XCTAssertFalse(painted(at - SyntaxHighlighter.lineReach - 1), "nothing before the reach")
        XCTAssertFalse(painted(at + 99 + SyntaxHighlighter.lineReach), "nothing after the reach")
    }

    func testAnOrdinaryLineIsStillPaintedWhole() {
        let storage = NSTextStorage(string: "a\n{\"key\": 1, \"other\": true}\nb", attributes: [.foregroundColor: NSColor.black])
        SyntaxHighlighter(language: .json, colors: Painter()).highlight(storage, in: NSRange(location: 5, length: 1))
        let last = storage.length - 3  // the line's closing brace
        XCTAssertNotEqual(storage.attribute(.foregroundColor, at: 2, effectiveRange: nil) as? NSColor, .black)
        XCTAssertNotEqual(storage.attribute(.foregroundColor, at: last, effectiveRange: nil) as? NSColor, .black)
    }
}

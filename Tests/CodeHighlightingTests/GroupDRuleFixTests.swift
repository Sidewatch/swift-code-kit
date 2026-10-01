//
//  GroupDRuleFixTests.swift
//  CodeHighlightingTests
//
//  A quote that is not a string delimiter, or a string form the table did not know, no longer
//  swallows the comment lines after it in Nim, Ninja, Objective-C++, PowerShell and PureScript.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

@MainActor
final class GroupDRuleFixTests: XCTestCase {
    private struct OneColourPerKind: TokenColorProviding {
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor { kind == .comment ? .systemGreen : .systemRed }
    }

    /// Whether the last line of `source` (a comment) comes out wholly comment-coloured.
    private func lastLineIsComment(_ source: String, _ language: Language) -> Bool {
        let storage = NSTextStorage(string: source + "\n", attributes: [.foregroundColor: NSColor.black])
        SyntaxHighlighter(language: language, colors: OneColourPerKind())
            .highlight(storage, in: NSRange(location: 0, length: storage.length))
        let ns = storage.string as NSString
        let start = ns.range(of: "\n", options: .backwards, range: NSRange(location: 0, length: ns.length - 1)).upperBound
        for i in start..<(ns.length - 1) {
            let scalar = Unicode.Scalar(ns.character(at: i))!
            if CharacterSet.whitespaces.contains(scalar) { continue }
            if storage.attribute(.foregroundColor, at: i, effectiveRange: nil) as? NSColor != .systemGreen { return false }
        }
        return true
    }

    func testNimTypedNumberSuffixesOpenNoCharLiteral() {
        XCTAssertTrue(lastLineIsComment("let a = 1'i8\nlet b = 1'i16\nlet c = 1'u8\n# a note", .nim))
    }

    func testNimRawStringWithDoubledQuoteEndsWhereItShould() {
        XCTAssertTrue(lastLineIsComment("let r = r\"C:\\no \"\"q\"\" end\"\nlet c = '\\x41'\n# a note", .nim))
    }

    func testNinjaQuoteIsOrdinaryText() {
        XCTAssertTrue(lastLineIsComment("rule cc\n  description = don't build $out\n# a note", .ninja))
    }

    func testObjectiveCppRawStringAndDigitSeparator() {
        XCTAssertTrue(lastLineIsComment("constexpr int k = 1'000;\nauto s = R\"d(raw )\" inside)d\";\n// a note", .objectivecpp))
    }

    func testPowerShellHereStringWithQuoteInside() {
        XCTAssertTrue(lastLineIsComment("$h = @'\nit's raw\n'@\n# a note", .powershell))
    }

    func testPowerShellDoubleQuotedBacktickEscape() {
        XCTAssertTrue(lastLineIsComment("$d = \"a `\" b\"\n$e = 'it''s'\n# a note", .powershell))
    }

    func testPureScriptTripleQuotedStringAndPrimedNames() {
        XCTAssertTrue(lastLineIsComment("x = \"\"\"say \"hi\nthere\"\"\"\ndata Symbol' = Symbol'\n-- a note", .purescript))
    }
}

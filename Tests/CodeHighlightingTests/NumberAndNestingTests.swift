//
//  NumberAndNestingTests.swift
//  CodeHighlightingTests
//
//  The shared number pattern reads modern literals; nesting block comments nest.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

/// The corpus renders showed `1_000_000`, `0xFF`, `0o755` and `1.5e-3` uncoloured in every table that
/// used the shared number pattern (it read `\d+(\.\d+)?` only), and nesting comments — F#'s
/// `(* (* *) *)`, D's `/+ /+ +/ +/`, Lisp's `#| #| |# |#` — painted as code after the inner close.
@MainActor
final class NumberAndNestingTests: XCTestCase {
    private struct Colours: TokenColorProviding {
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor {
            switch kind {
            case .number: return .systemOrange
            case .comment: return .systemGreen
            default: return .systemRed
            }
        }
    }

    private func painted(_ text: String, _ language: Language) -> NSTextStorage {
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: NSColor.black])
        SyntaxHighlighter(language: language, colors: Colours()).highlight(storage, in: NSRange(location: 0, length: storage.length))
        return storage
    }

    private func colour(of token: String, in storage: NSTextStorage) -> NSColor? {
        let r = (storage.string as NSString).range(of: token)
        guard r.location != NSNotFound else { return nil }
        // Every character of the token wears one colour.
        let first = storage.attribute(.foregroundColor, at: r.location, effectiveRange: nil) as? NSColor
        for i in r.location..<NSMaxRange(r) where storage.attribute(.foregroundColor, at: i, effectiveRange: nil) as? NSColor != first {
            return nil
        }
        return first
    }

    func testTheSharedNumberPatternReadsModernLiterals() {
        let tokens = ["1_000_000", "0xFF_FF", "0o755", "0b1010", "1.5e-3", "255uy", "42"]
        var failing: [String] = []
        for language in Language.allCases where RuleTables.table(for: language).contains(where: { $0.0 == RuleTables.decimal.0 }) {
            let storage = painted("x = " + tokens.joined(separator: " + ") + "\n", language)
            for t in tokens where colour(of: t, in: storage) != .systemOrange { failing.append("\(language.rawValue): \(t)") }
        }
        XCTAssertEqual(failing, [])
    }

    func testANumberInsideANameIsNotANumber() {
        let storage = painted("let item42x = sku2 + 3\n", .fsharp)
        XCTAssertNotEqual(colour(of: "42", in: storage), .systemOrange)
        XCTAssertEqual(colour(of: "3", in: storage), .systemOrange)
    }

    func testNestedBlockCommentsStayCommentsToTheOuterClose() {
        var failing: [String] = []
        for language in RuleTables.nestingLanguages.sorted(by: { $0.rawValue < $1.rawValue }) {
            guard let b = language.blockComment else { continue }
            let text = "\(b.open) outer \(b.open) inner \(b.close) still outer \(b.close)\n"
            if colour(of: "still outer", in: painted(text, language)) != .systemGreen { failing.append(language.rawValue) }
        }
        XCTAssertEqual(failing, [])
        XCTAssertEqual(colour(of: "still outer", in: painted("/+ outer /+ inner +/ still outer +/\n", .d)), .systemGreen)
    }
}

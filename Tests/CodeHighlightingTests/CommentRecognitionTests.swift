//
//  CommentRecognitionTests.swift
//  CodeHighlightingTests
//
//  Every language's own line comment is painted as a comment by the regex tier.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

/// A language that falls back to its family's table used to inherit the FAMILY's comment syntax: F#
/// and Gleam lost `//`, SPARQL and Cap'n Proto `#`, and VB.NET's `'` and Vim script's `"` came out as
/// strings. The language table already records each language's own tokens, so every language that has
/// one is swept here: a line that is only a comment must be painted as one, whole.
@MainActor
final class CommentRecognitionTests: XCTestCase {
    private struct OneColourPerKind: TokenColorProviding {
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor { kind == .comment ? .systemGreen : .systemRed }
    }

    /// Whether every visible character of `line` comes out comment-coloured.
    private func paintedAsComment(_ line: String, _ language: Language) -> Bool {
        let storage = NSTextStorage(string: line + "\n", attributes: [.foregroundColor: NSColor.black])
        SyntaxHighlighter(language: language, colors: OneColourPerKind())
            .highlight(storage, in: NSRange(location: 0, length: storage.length))
        let ns = storage.string as NSString
        for i in 0..<ns.length {
            guard let scalar = Unicode.Scalar(ns.character(at: i)), !CharacterSet.whitespacesAndNewlines.contains(scalar) else { continue }
            if storage.attribute(.foregroundColor, at: i, effectiveRange: nil) as? NSColor != .systemGreen { return false }
        }
        return true
    }

    /// Languages whose comment token is positional or whose table deliberately reads it otherwise.
    static let positional: Set<Language> = [
        .cobol,  // `*` in column 7 of fixed format, not at the start of a line
        .plainText, .csv, .tsv, .log,
    ]

    func testEveryLanguagesOwnLineCommentIsPaintedAsAComment() {
        var failing: [String] = []
        for language in Language.allCases where !Self.positional.contains(language) {
            guard let token = language.lineCommentToken, !token.isEmpty else { continue }
            if !paintedAsComment("\(token) the stock count is reconciled nightly", language) {
                failing.append("\(language.rawValue) (\(token))")
            }
        }
        XCTAssertEqual(failing, [], "line comments not painted as comments")
    }

    func testEveryLanguagesOwnBlockCommentIsPaintedAsAComment() {
        var failing: [String] = []
        for language in Language.allCases where !Self.positional.contains(language) {
            guard let block = language.blockComment else { continue }
            if !paintedAsComment("\(block.open)\nreconciled nightly\n\(block.close)", language) {
                failing.append("\(language.rawValue) (\(block.open) \(block.close))")
            }
        }
        XCTAssertEqual(failing, [], "block comments not painted as comments")
    }

    func testAQuoteThatOpensACommentDoesNotOpenAString() {
        XCTAssertTrue(paintedAsComment("' a VB.NET comment, not a string", .vbnet))
        XCTAssertTrue(paintedAsComment("\" a Vim script comment, not a string", .vimscript))
    }

    /// A backslash before a line break continues a string (Haskell's gap, a shell's `"…\`) — an
    /// escape that could not cover the newline left the string unmatched, and every quote after it
    /// paired with the wrong partner, painting the rest of the file inside out.
    func testAnEscapedLineBreakDoesNotTurnTheRestOfTheFileInsideOut() {
        // After the gap one quoted string, a comment, then one more: out of phase, the closing quote
        // of `gap"` pairs with the opening quote of `"a"`, and `a"` pairs with the quote of `"b"` —
        // swallowing the comment between them as a string.
        let haskell = "strings = [ \"multi\\\n  \\line gap\", \"a\" ]\n-- the comment after them\nb = \"b\"\n"
        let storage = NSTextStorage(string: haskell, attributes: [.foregroundColor: NSColor.black])
        SyntaxHighlighter(language: .haskell, colors: OneColourPerKind()).highlight(
            storage, in: NSRange(location: 0, length: storage.length))
        let at = (storage.string as NSString).range(of: "the comment after").location
        XCTAssertEqual(storage.attribute(.foregroundColor, at: at, effectiveRange: nil) as? NSColor, .systemGreen)
        XCTAssertTrue(paintedAsComment("# a fish comment", .fish))
    }

    func testSecondCommentFormsAreComments() {
        XCTAssertTrue(paintedAsComment("# shell-style comment", .thrift))
        XCTAssertTrue(paintedAsComment("! an exclamation comment", .properties))
        XCTAssertTrue(paintedAsComment("REM an old-style remark", .vbnet))
        XCTAssertTrue(paintedAsComment("* a statement comment;", .sas))
        XCTAssertTrue(paintedAsComment("* a star comment", .stata))
    }

    func testOrgKeywordLinesAreNotComments() {
        XCTAssertTrue(paintedAsComment("# a real Org comment", .org))
        XCTAssertFalse(paintedAsComment("#+TITLE: Inventory service notes", .org))
    }
}

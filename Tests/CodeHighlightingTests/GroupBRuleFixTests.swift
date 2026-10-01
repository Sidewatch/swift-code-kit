//
//  GroupBRuleFixTests.swift
//  CodeHighlightingTests
//
//  Fish, F#, Git commit messages, Haskell and INI: a string that ends where the language ends it.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

/// Each snippet is the smallest text that used to run a string past its real end, so the comment after
/// it was painted as a string; the comment must now be comment-coloured, whole.
@MainActor
final class GroupBRuleFixTests: XCTestCase {
    private struct OneColourPerKind: TokenColorProviding {
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor { kind == .comment ? .systemGreen : .systemRed }
    }

    /// Whether every visible character of the line holding `marker` comes out comment-coloured.
    private func lineIsComment(_ marker: String, in text: String, _ language: Language) -> Bool {
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: NSColor.black])
        SyntaxHighlighter(language: language, colors: OneColourPerKind())
            .highlight(storage, in: NSRange(location: 0, length: storage.length))
        let ns = storage.string as NSString
        let line = ns.lineRange(for: ns.range(of: marker))
        for i in line.location..<NSMaxRange(line) {
            guard let s = Unicode.Scalar(ns.character(at: i)), !CharacterSet.whitespacesAndNewlines.contains(s) else { continue }
            if storage.attribute(.foregroundColor, at: i, effectiveRange: nil) as? NSColor != .systemGreen { return false }
        }
        return true
    }

    /// Fish's single quotes honour `\'`, and an escaped quote outside quotes is no quote at all.
    func testFishEscapedQuotesDoNotRunAStringPastItsEnd() {
        XCTAssertTrue(lineIsComment("# after", in: "set s 'a \\' b'\n# after\necho 'x'\n", .fish))
        XCTAssertTrue(lineIsComment("# after", in: "echo \\'a\\' b\n# after\necho 'x'\n", .fish))
    }

    /// A character literal such as `'"'` is not a string opener.
    func testFSharpCharacterLiteralsDoNotOpenAString() {
        XCTAssertTrue(lineIsComment("// after", in: "let q = ['\"'; 'a']\n// after\nlet s = \"x\"\n", .fsharp))
        XCTAssertTrue(lineIsComment("// after", in: "let query' = 1\nlet c = '\\''\n// after\nlet s = \"x\"\n", .fsharp))
    }

    /// An apostrophe in the prose is not a quote; commit messages have no strings.
    func testGitCommitApostropheDoesNotOpenAString() {
        XCTAssertTrue(lineIsComment("# after", in: "fix the bar's filter\n\n# after\nit's done\n", .gitcommit))
    }

    /// A `"""` multiline string, and a `'"'` character, leave the quotes after them paired correctly.
    func testHaskellTripleQuotesAndCharacterLiteralsDoNotLeak() {
        XCTAssertTrue(lineIsComment("-- after", in: "banner = \"\"\"\n  say \" hi\n  \"\"\"\n-- after\nb = \"b\"\n", .haskell))
        XCTAssertTrue(lineIsComment("-- after", in: "data Void'\nc = '\"'\n-- after\nb = \"b\"\n", .haskell))
    }

    /// An unterminated quote ends at the line end instead of swallowing the lines below.
    func testINIUnterminatedQuoteEndsAtTheLineEnd() {
        XCTAssertTrue(lineIsComment("; after", in: "key = \"unterminated\n; after\nother = \"x\"\n", .ini))
    }
}

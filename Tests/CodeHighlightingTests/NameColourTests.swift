//
//  NameColourTests.swift
//  CodeHighlightingTests
//
//  Plain names wear the identifier role: in programming languages only, never over another role.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import CodeLanguage
import SwiftTreeSitter
import XCTest

@testable import CodeHighlighting

@MainActor
final class NameColourTests: XCTestCase {
    private struct Colours: TokenColorProviding {
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor {
            switch kind {
            case .identifier: return .systemTeal
            case .keyword: return .systemPurple
            case .string: return .systemGreen
            case .comment: return .systemGray
            case .number: return .systemOrange
            default: return .systemRed
            }
        }
    }

    private func colour(of marker: String, in text: String, _ language: CodeLanguage.Language) -> NSColor? {
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: NSColor.black])
        SyntaxHighlighter(language: language, colors: Colours()).highlight(storage, in: NSRange(location: 0, length: storage.length))
        let r = (text as NSString).range(of: marker)
        XCTAssertNotEqual(r.location, NSNotFound, marker)
        return storage.attribute(.foregroundColor, at: r.location, effectiveRange: nil) as? NSColor
    }

    /// A name in a programming language wears the identifier colour; keywords, strings, comments and
    /// numbers around it keep theirs.
    func testNamesWearTheIdentifierColourAndEveryOtherRoleWins() {
        let zig = "const total = count + 1; const label = \"name\"; // count"
        XCTAssertEqual(colour(of: "total", in: zig, .zig), .systemTeal)
        XCTAssertEqual(colour(of: "count +", in: zig, .zig), .systemTeal)
        XCTAssertEqual(colour(of: "const", in: zig, .zig), .systemPurple)
        XCTAssertEqual(colour(of: "1;", in: zig, .zig), .systemOrange)
        XCTAssertEqual(colour(of: "// count", in: zig, .zig), .systemGray)
        XCTAssertEqual(colour(of: "\"name\"", in: zig, .zig), .systemGreen)
        XCTAssertEqual(colour(of: "set-car!", in: "(set-car! pair 1)", .scheme), .systemTeal)
        XCTAssertEqual(colour(of: "foldl'", in: "total = foldl' (+) 0 xs", .haskell), .systemTeal)
    }

    /// Where a bare word is a command, a directive or a key, it stays plain text.
    func testShellConfigAndDataWordsStayPlain() {
        XCTAssertEqual(colour(of: "hello", in: "echo hello world", .bash), .black)
        XCTAssertEqual(
            colour(of: "proxy_pass", in: "location / { proxy_pass upstream; }", .nginx),
            colour(of: "proxy_pass", in: "location / { proxy_pass upstream; }", .nginx))
        XCTAssertNil(RuleTables.namePattern(for: .bash))
        XCTAssertNil(RuleTables.namePattern(for: .yaml))
        XCTAssertNil(RuleTables.namePattern(for: .markdown))
        XCTAssertNil(RuleTables.namePattern(for: .sql))
        XCTAssertNil(RuleTables.namePattern(for: .css))
    }

    /// The tree-sitter catch-all maps to the identifier role, and its hits sort below every pass: a LATER
    /// pass's name (an injected layer) never repaints an earlier pass's colour (the host's type).
    func testTreeSitterNameCaptureIsTheIdentifierRoleAndOnlyFills() throws {
        XCTAssertEqual(TreeSitterHighlighter.role(for: "identifier.plain"), "identifier")
        XCTAssertNil(TreeSitterHighlighter.role(for: "variable"))
        let lang = try XCTUnwrap(TreeSitterHighlighter.tsLanguage(for: .python), "grammar not loaded")
        let parser = Parser()
        try parser.setLanguage(lang)
        let text = "total = 1"
        let tree = try XCTUnwrap(parser.parse(text))
        let host = try Query(language: lang, data: Data("(identifier) @type".utf8))
        let injected = try Query(language: lang, data: Data("(identifier) @identifier.plain".utf8))
        let saved = HighlightTheme.colors
        HighlightTheme.colors = Colours()
        defer { HighlightTheme.colors = saved }
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: NSColor.black])
        let clip = NSRange(location: 0, length: storage.length)
        var base = 0
        let hits =
            TreeSitterHighlighter.collectHits(host, tree: tree, source: text as NSString, offset: 0, clip: clip, nextBase: &base)
            + TreeSitterHighlighter.collectHits(injected, tree: tree, source: text as NSString, offset: 0, clip: clip, nextBase: &base)
        TreeSitterHighlighter.applyResolved(hits: hits, clip: clip, defaultColor: .black, into: storage)
        XCTAssertEqual(storage.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor, .systemRed)
    }
}

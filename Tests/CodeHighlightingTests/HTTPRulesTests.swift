//
//  HTTPRulesTests.swift
//  CodeHighlightingTests
//
//  Tests for the `.http` rule table: method, address, version, placeholders, headers, body and
//  comments each get their token kind, read back through a marker palette.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
@testable import CodeHighlighting
import CodeLanguage

/// Tests for the `.http` rule table: method, address, version, placeholders, headers, body and
/// comments each get their token kind, read back through a marker palette.
@MainActor
final class HTTPRulesTests: XCTestCase {

    /// One unique colour per token kind so a painted run reverse-maps to its kind.
    private struct Markers: TokenColorProviding {
        static let kinds: [TokenKind] = [.comment, .string, .keyword, .type, .number, .function, .attribute, .variable, .property]
        func color(for kind: TokenKind) -> NSColor {
            if kind == .identifier { return foreground }  // plain names read as plain text here
            return NSColor(deviceRed: CGFloat((Self.kinds.firstIndex(of: kind) ?? -1) + 1) / 100, green: 0, blue: 0, alpha: 1)
        }
        var foreground: NSColor { NSColor(deviceRed: 0, green: 0, blue: 0, alpha: 1) }
        static func kind(of color: NSColor) -> TokenKind? {
            guard let c = color.usingColorSpace(.deviceRGB) else { return nil }
            let i = Int(round(c.redComponent * 100)) - 1
            return kinds.indices.contains(i) ? kinds[i] : nil
        }
    }

    private let document = """
        ### Get one user
        GET https://api.example.com/users/1
        Accept: application/json
        If-Match: "v3:2026-10-03T09:00:00Z"

        {"id": 1, "active": true}

        ### Versioned, lowercase, with a placeholder
        @host = api.example.com
        get https://{{host}}/status HTTP/1.1
        // a comment
        """

    private func kinds() -> (at: (String) -> TokenKind?, storage: NSTextStorage) {
        let storage = NSTextStorage(string: document)
        SyntaxHighlighter(language: .http, colors: Markers()).highlight(storage, in: NSRange(location: 0, length: storage.length))
        let ns = storage.string as NSString
        return (
            { needle in
                let r = ns.range(of: needle)
                guard r.location != NSNotFound,
                    let color = storage.attribute(.foregroundColor, at: r.location, effectiveRange: nil) as? NSColor
                else { return nil }
                return Markers.kind(of: color)
            }, storage
        )
    }

    func testDotHTTPIsItsOwnLanguage() {
        XCTAssertEqual(Language.detect(filename: "requests.http"), .http)
    }

    func testEachPartOfARequestGetsItsRole() {
        let (kind, _) = kinds()
        XCTAssertEqual(kind("### Get"), .comment)
        XCTAssertEqual(kind("GET"), .keyword)
        XCTAssertEqual(kind("https://api"), .string)
        XCTAssertEqual(kind("Accept"), .property)
        XCTAssertEqual(kind("application/json"), .string)
        XCTAssertEqual(kind("\"v3:2026"), .string, "a header value holding a colon is one value")
    }

    func testTheBodyIsPaintedAsJSON() {
        let (kind, _) = kinds()
        XCTAssertEqual(kind("\"id\""), .string)
        XCTAssertEqual(kind("1, "), .number)
        XCTAssertEqual(kind("true"), .number)
    }

    func testVersionPlaceholdersAndLowercaseMethods() {
        let (kind, _) = kinds()
        XCTAssertEqual(kind("get "), .keyword)
        XCTAssertEqual(kind("HTTP/1.1"), .keyword)
        XCTAssertEqual(kind("{{host}}"), .type)
        XCTAssertEqual(kind("@host"), .type)
        XCTAssertEqual(kind("// a comment"), .comment)
    }

    func testNewlinesAreNeverPainted() {
        let (_, storage) = kinds()
        let ns = storage.string as NSString
        let eol = ns.range(of: "\n").location
        let color = storage.attribute(.foregroundColor, at: eol, effectiveRange: nil) as? NSColor
        XCTAssertNil(color.flatMap(Markers.kind(of:)), "the separator's newline keeps the foreground colour")
    }
}

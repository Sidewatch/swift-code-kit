//
//  StaticHostRulesTests.swift
//  CodeHighlightingTests
//
//  `_headers` and `_redirects`: each part of a header block and a redirect line gets its token kind,
//  read back through a marker palette.
//
//  Created by David Sherlock on 10/10/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import CodeLanguage
import XCTest

@testable import CodeHighlighting

@MainActor
final class StaticHostRulesTests: XCTestCase {

    /// One unique colour per token kind so a painted run reverse-maps to its kind.
    private struct Markers: TokenColorProviding {
        static let kinds: [TokenKind] = [.comment, .string, .keyword, .type, .number, .function, .attribute, .variable, .property]
        func color(for kind: TokenKind) -> NSColor {
            if kind == .identifier { return foreground }
            return NSColor(deviceRed: CGFloat((Self.kinds.firstIndex(of: kind) ?? -1) + 1) / 100, green: 0, blue: 0, alpha: 1)
        }
        var foreground: NSColor { NSColor(deviceRed: 0, green: 0, blue: 0, alpha: 1) }
        static func kind(of color: NSColor) -> TokenKind? {
            guard let c = color.usingColorSpace(.deviceRGB) else { return nil }
            let i = Int(round(c.redComponent * 100)) - 1
            return kinds.indices.contains(i) ? kinds[i] : nil
        }
    }

    private let headers = """
        # Every page: never framed.
        /*
          X-Frame-Options: DENY
          Content-Security-Policy: default-src 'self'; img-src https://*.example.com

        /blog/:slug/*
          Cache-Control: public, max-age=3600
          ! X-Robots-Tag
        """

    private let redirects = """
        # Moved pages
        /home              /
        /blog/*            /posts/:splat        301
        /news/:year/:id    https://news.example.com/:id   302!
        /store id=:id      /items/:id           200
        /fr/*              /fr/index.html       200  Country=fr
        /docs              /guide#start
        """

    private func kinds(_ text: String, _ language: Language) -> (String, Int) -> TokenKind? {
        let storage = NSTextStorage(string: text)
        SyntaxHighlighter(language: language, colors: Markers()).highlight(storage, in: NSRange(location: 0, length: storage.length))
        let ns = storage.string as NSString
        return { needle, offset in
            let r = ns.range(of: needle)
            guard r.location != NSNotFound,
                let color = storage.attribute(.foregroundColor, at: r.location + offset, effectiveRange: nil) as? NSColor
            else { return nil }
            return Markers.kind(of: color)
        }
    }

    func testTheFileNamesAreTheirOwnLanguages() {
        XCTAssertEqual(Language.detect(filename: "_headers"), .staticheaders)
        XCTAssertEqual(Language.detect(filename: "_redirects"), .staticredirects)
        XCTAssertEqual(Language.detect(filename: "headers"), .plainText)
    }

    func testAHeaderBlockGetsItsRoles() {
        let kind = kinds(headers, .staticheaders)
        XCTAssertEqual(kind("# Every page", 0), .comment)
        XCTAssertEqual(kind("/blog/", 0), .type, "the URL pattern")
        XCTAssertEqual(kind(":slug", 0), .variable, "a placeholder in the pattern")
        XCTAssertEqual(kind("/*\n", 1), .variable, "a splat in the pattern")
        XCTAssertEqual(kind("X-Frame-Options", 0), .property)
        XCTAssertEqual(kind("DENY", 0), .string)
        XCTAssertEqual(kind("default-src", 0), .string, "a value is one value, whatever it holds")
        XCTAssertEqual(kind("*.example.com", 0), .string, "a `*` in a value is the value's, not a splat")
        XCTAssertEqual(kind("! X-Robots-Tag", 0), .keyword, "a detach line")
    }

    func testARedirectLineGetsItsRoles() {
        let kind = kinds(redirects, .staticredirects)
        XCTAssertEqual(kind("# Moved", 0), .comment)
        XCTAssertEqual(kind("/home", 0), .type, "the source")
        XCTAssertEqual(kind("/posts/", 0), .type, "the destination")
        XCTAssertEqual(kind(":splat", 0), .variable)
        XCTAssertEqual(kind("/blog/*", 6), .variable, "a splat in the source")
        XCTAssertEqual(kind("301", 0), .number)
        XCTAssertEqual(kind("302!", 0), .number)
        XCTAssertEqual(kind("302!", 3), .keyword, "`!` forces the rule")
        XCTAssertEqual(kind("https://news", 0), .type)
        XCTAssertEqual(kind("id=:id", 0), .property, "a query condition's key")
        XCTAssertEqual(kind("Country=fr", 0), .property)
        XCTAssertEqual(kind("#start", 0), .type, "a `#` inside a URL is not a comment")
    }
}

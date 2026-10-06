//
//  OwnCommentAndMarkupScopeTests.swift
//  CodeHighlightingTests
//
//  Comment markers that are not comments in context; quotes and attribute names in markup.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import CodeLanguage
import XCTest

@testable import CodeHighlighting

@MainActor
final class OwnCommentAndMarkupScopeTests: XCTestCase {
    private struct Colours: TokenColorProviding {
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor {
            switch kind {
            case .comment: return .systemGray
            case .string: return .systemGreen
            case .property: return .systemOrange
            default: return .systemBlue
            }
        }
    }

    /// The colour at the first character of `marker`.
    private func colour(of marker: String, in text: String, _ language: Language) -> NSColor? {
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: NSColor.black])
        SyntaxHighlighter(language: language, colors: Colours()).highlight(storage, in: NSRange(location: 0, length: storage.length))
        let r = (text as NSString).range(of: marker)
        XCTAssertNotEqual(r.location, NSNotFound, marker)
        return storage.attribute(.foregroundColor, at: r.location, effectiveRange: nil) as? NSColor
    }

    /// In a markup-family language without a table of its own (XSLT), a quoted value is a string inside a
    /// tag only; between tags the quotes are text.
    func testMarkupQuotesAreStringsOnlyInsideTags() {
        let xslt = "<xsl:processing-instruction name=\"report\">format=\"html\"</xsl:processing-instruction>\n"
        XCTAssertEqual(colour(of: "\"report\"", in: xslt, .xslt), .systemGreen)
        XCTAssertNotEqual(colour(of: "\"html\"", in: xslt, .xslt), .systemGreen)
    }

    /// An AsciiDoc comment is a line that starts with `//`; a `//` inside a line is text.
    func testAsciiDocCommentOnlyAtLineStart() {
        let text = "Divide a // b in prose.\n// a comment\n"
        XCTAssertNotEqual(colour(of: "b in prose", in: text, .asciidoc), .systemGray)
        XCTAssertEqual(colour(of: "// a comment", in: text, .asciidoc), .systemGray)
    }

    /// Crystal's `#{` opens an interpolation, not a comment.
    func testCrystalInterpolationOpensNoComment() {
        let text = "x = 1 + #{y}\n# note\n"
        XCTAssertNotEqual(colour(of: "#{y}", in: text, .crystal), .systemGray)
        XCTAssertEqual(colour(of: "# note", in: text, .crystal), .systemGray)
    }

    /// A markup attribute name (`class=`) wears the property role in every template language, as the HTML
    /// grammar paints it; the attribute role is for annotations (`@Override`, `#[derive]`).
    func testMarkupAttributeNamesWearThePropertyRole() {
        let tag = "<div class=\"row\">x</div>\n"
        let languages: [Language] = [
            .html, .xslt, .astro, .handlebars, .erb, .liquid, .razor, .twig, .blade, .jinja, .jsp, .smarty, .cfml,
            .velocity, .marko,
        ]
        for language in languages {
            XCTAssertEqual(colour(of: "class", in: tag, language), .systemOrange, "\(language)")
        }
        XCTAssertEqual(colour(of: "class", in: "%p(class=\"row\") x\n", .haml), .systemOrange)
        XCTAssertEqual(colour(of: "class=", in: "div class=\"row\" x\n", .slim), .systemOrange)
        XCTAssertEqual(colour(of: "color", in: "digraph g { a [color=red]; }\n", .dot), .systemOrange)
    }
}

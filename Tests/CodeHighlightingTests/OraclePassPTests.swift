//
//  OraclePassPTests.swift
//  CodeHighlightingTests
//
//  The paint-time round of the accuracy pass: a scoped string or comment rule's search starts at its next
//  region without changing what it finds, and a single-file component's colours reach the storage once, in
//  document order.
//
//  Created by David Sherlock on 10/7/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import CodeLanguage
import XCTest

@testable import CodeHighlighting

@MainActor
final class OraclePassPTests: XCTestCase {
    private struct Colours: TokenColorProviding {
        let foreground = NSColor(srgbRed: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        func color(for kind: TokenKind) -> NSColor {
            kind == .string
                ? NSColor(srgbRed: 0.1, green: 0.6, blue: 0.2, alpha: 1) : NSColor(srgbRed: 0.6, green: 0.1, blue: 0.2, alpha: 1)
        }
    }

    /// Whether every character of the first `marker` in `text` wears the string colour after painting it with `defs`.
    private func isString(_ marker: String, in text: String, defs: [(String, TokenKind)]) -> Bool {
        let colours = Colours()
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colours.foreground])
        SyntaxHighlighter(defs: defs, regexOptions: .anchorsMatchLines, colors: colours)
            .highlight(storage, in: NSRange(location: 0, length: storage.length))
        let range = (text as NSString).range(of: marker)
        XCTAssertNotEqual(range.location, NSNotFound, "marker \(marker) missing")
        return (range.location..<NSMaxRange(range)).allSatisfy {
            (storage.attribute(.foregroundColor, at: $0, effectiveRange: nil) as? NSColor) == colours.color(for: .string)
        }
    }

    /// A rule scoped to the `<…>` regions.
    private func scoped(_ body: String) -> (String, TokenKind) {
        (RuleScope.marker(opens: ["<"], closes: [">"], within: 100) + body, .string)
    }

    // MARK: The search of a scoped string rule

    /// The search that starts at a region still sees the text before it: a word boundary at the region's first
    /// character is judged against the character before it, as the search from the start of the text judged it.
    func testAScopedRuleStartingAtItsRegionStillSeesTheTextBeforeIt() {
        XCTAssertTrue(isString("<y>", in: "plain text x<y> more\n", defs: [scoped("\\b<y>")]))
        XCTAssertFalse(isString("<z>", in: "plain text <z> more\n", defs: [scoped("\\b<z>")]))
    }

    /// The place a search jumps to is not the start of a line: `^` there matches only where a line starts.
    func testAScopedRuleNeverAnchorsAtTheRegionItJumpsTo() {
        let text = "plain text x<y> more\n<z> again\n"
        XCTAssertFalse(isString("<y>", in: text, defs: [scoped("^<[yz]>")]))
        XCTAssertTrue(isString("<z>", in: text, defs: [scoped("^<[yz]>")]))
    }

    // MARK: A single-file component's writes

    /// A storage that records where each colour write lands.
    private final class RecordingStorage: NSTextStorage {
        private let backing: NSMutableAttributedString
        private(set) var writes: [Int] = []

        init(_ text: String, colour: NSColor) {
            backing = NSMutableAttributedString(string: text, attributes: [.foregroundColor: colour])
            super.init()
        }

        required init?(coder: NSCoder) { fatalError("not archived") }

        required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
            fatalError("not read from a pasteboard")
        }

        override var string: String { backing.string }

        override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
            backing.attributes(at: location, effectiveRange: range)
        }

        override func replaceCharacters(in range: NSRange, with str: String) { backing.replaceCharacters(in: range, with: str) }

        override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
            backing.setAttributes(attrs, range: range)
        }

        override func addAttribute(_ name: NSAttributedString.Key, value: Any, range: NSRange) {
            writes.append(range.location)
            backing.addAttribute(name, value: value, range: range)
        }
    }

    /// The script below the template paints first and the template's markup and expressions after it, but the
    /// storage receives the colours in document order: a write into the middle of a large storage's attribute
    /// runs moves every run after it.
    func testASingleFileComponentWritesItsColoursInDocumentOrder() {
        let text = """
            <template>
              <p class="note">{{ count + 1 }} items</p>
            </template>
            <script>
            const count = 3
            </script>

            """
        let colours = Colours()
        let storage = RecordingStorage(text, colour: colours.foreground)
        let highlighter = EmbeddedMarkupHighlighter(language: .vue, colors: colours)
        highlighter?.highlight(storage, in: NSRange(location: 0, length: storage.length))
        // The first write resets the whole text; every colour after it lands at or after the one before.
        let colourWrites = Array(storage.writes.dropFirst())
        XCTAssertGreaterThan(colourWrites.count, 2)
        XCTAssertEqual(colourWrites, colourWrites.sorted())
        // And the colours are the ones painted: the class name's quotes are a string.
        let quote = (text as NSString).range(of: "\"note\"")
        XCTAssertEqual(
            storage.attribute(.foregroundColor, at: quote.location, effectiveRange: nil) as? NSColor, colours.color(for: .string))
    }
}

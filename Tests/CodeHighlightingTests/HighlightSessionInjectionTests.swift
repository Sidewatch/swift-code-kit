//
//  HighlightSessionInjectionTests.swift
//  CodeHighlightingTests
//
//  A session's injections: an HTML document's template tags are found once per edit and colour as the stateless
//  highlighter colours them; an injected language whose grammar is not compiled yet is compiled in the background,
//  never in the pass.
//
//  Created by David Sherlock on 10/29/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import CodeLanguage
import XCTest

@testable import CodeHighlighting

@MainActor
final class HighlightSessionInjectionTests: XCTestCase {
    private let page = "<div>{{ total + 1 }}</div>\n<# if ( shown ) { #><p>Hello</p><# } #>\n<script>let answer = 42;</script>\n"

    override func setUp() async throws {
        try await super.setUp()
        try await MainActor.run {
            TreeSitterHighlighter.installGrammarForTesting(try SourceGrammars.html(), for: .html)
            TreeSitterHighlighter.installGrammarForTesting(try SourceGrammars.javascript(), for: .javascript)
        }
    }

    override func tearDown() async throws {
        await MainActor.run {
            TreeSitterHighlighter.forgetGrammarForTesting(.html)
            TreeSitterHighlighter.forgetGrammarForTesting(.javascript)
            TreeSitterHighlighter.onRequestedGrammarReady = nil
        }
        try await super.tearDown()
    }

    private func colours(of storage: NSTextStorage) -> [NSColor?] {
        (0..<storage.length).map { storage.attribute(.foregroundColor, at: $0, effectiveRange: nil) as? NSColor }
    }

    /// Every pass over an HTML document asked for the whole document's template tags, and finding them read the
    /// whole document: the session finds them once per edit, and colours exactly as the stateless highlighter does.
    func testTemplateTagsAreFoundOncePerEditAndColourAsBefore() throws {
        let session = HighlightSession(grammar: try SourceGrammars.html())
        let storage = NSTextStorage(string: page, attributes: [.foregroundColor: HighlightTheme.colors.foreground])
        let lines = (page as NSString).components(separatedBy: "\n")
        var location = 0
        for line in lines where !line.isEmpty {  // a pass per line, as the viewport and the minimap ask
            let length = (line as NSString).length
            session.highlight(in: storage, text: storage.string, clip: NSRange(location: location, length: length))
            location += length + 1
        }
        XCTAssertEqual(session.templateTagSearchesForTesting, 1, "searched once, not once a pass")

        let stateless = NSTextStorage(string: page, attributes: [.foregroundColor: HighlightTheme.colors.foreground])
        try XCTUnwrap(TreeSitterHighlighter(language: .html)).highlight(stateless, in: NSRange(location: 0, length: stateless.length))
        XCTAssertEqual(colours(of: storage), colours(of: stateless), "the same colours as the highlighter that searches every time")
        let one = (page as NSString).range(of: "1 }}")
        XCTAssertNotEqual(
            storage.attribute(.foregroundColor, at: one.location, effectiveRange: nil) as? NSColor, HighlightTheme.colors.foreground,
            "the expression inside {{ }} is coloured as code")

        storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "<p>new</p>\n")
        session.noteEdit(range: NSRange(location: 0, length: 0), replacementLength: 11, newText: storage.string)
        session.highlight(in: storage, text: storage.string, clip: NSRange(location: 0, length: 11))
        XCTAssertEqual(session.templateTagSearchesForTesting, 2, "an edit is a new version")
    }

    /// A page with no `<#` and no `{{` is never searched.
    func testAPageWithNoTemplateTagIsNeverSearched() throws {
        let session = HighlightSession(grammar: try SourceGrammars.html())
        let text = "<p>{ not a tag }</p>\n<script>let x = 1;</script>\n"
        let storage = NSTextStorage(string: text)
        session.highlight(in: storage, text: text, clip: NSRange(location: 0, length: storage.length))
        XCTAssertEqual(session.templateTagSearchesForTesting, 0)
    }

    /// An injected language whose grammar is not compiled yet is left in the host's colours and compiled in the
    /// background, never in the pass; the host paints again when it lands, and then it is coloured.
    func testAnInjectedGrammarNotCompiledYetIsCompiledInTheBackground() throws {
        TreeSitterHighlighter.forgetGrammarForTesting(.javascript)
        let session = HighlightSession(grammar: try SourceGrammars.html())
        let storage = NSTextStorage(string: page, attributes: [.foregroundColor: HighlightTheme.colors.foreground])
        let landed = expectation(description: "the script's grammar landed")
        TreeSitterHighlighter.onRequestedGrammarReady = { if $0 == .javascript { landed.fulfill() } }
        session.highlight(in: storage, text: storage.string, clip: NSRange(location: 0, length: storage.length))
        XCTAssertTrue(TreeSitterHighlighter.isRequestedForTesting(.javascript), "its compile went to the background")
        let answer = (page as NSString).range(of: "42")
        XCTAssertEqual(
            storage.attribute(.foregroundColor, at: answer.location, effectiveRange: nil) as? NSColor, HighlightTheme.colors.foreground,
            "the script waits in the host's colours")
        wait(for: [landed], timeout: 30)
        TreeSitterHighlighter.installGrammarForTesting(try SourceGrammars.javascript(), for: .javascript)  // as the bundle would
        session.highlight(in: storage, text: storage.string, clip: NSRange(location: 0, length: storage.length))
        XCTAssertNotEqual(
            storage.attribute(.foregroundColor, at: answer.location, effectiveRange: nil) as? NSColor, HighlightTheme.colors.foreground,
            "painted again, the script is coloured")
    }
}

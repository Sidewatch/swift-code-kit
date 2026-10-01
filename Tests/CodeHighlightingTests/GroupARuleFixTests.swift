//
//  GroupARuleFixTests.swift
//  CodeHighlightingTests
//
//  ABAP, AsciiDoc, COBOL, CoffeeScript and Elixir: a string that leaked past its end no longer paints
//  the comment after it.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

/// Each snippet is the smallest thing from the corpus showcase that made a string run on; the line
/// named `marker` must come out comment-coloured, and the string before it string-coloured.
@MainActor
final class GroupARuleFixTests: XCTestCase {
    private struct OneColourPerKind: TokenColorProviding {
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor { kind == .comment ? .systemGreen : .systemRed }
    }

    /// The colour of the first character of `marker` in `text`: green for a comment, red otherwise.
    private func isComment(_ marker: String, in text: String, _ language: Language) -> Bool {
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: NSColor.black])
        SyntaxHighlighter(language: language, colors: OneColourPerKind())
            .highlight(storage, in: NSRange(location: 0, length: storage.length))
        let at = (text as NSString).range(of: marker).location
        return storage.attribute(.foregroundColor, at: at, effectiveRange: nil) as? NSColor == .systemGreen
    }

    func testABAPTemplateWithEscapedBarEndsAtItsClosingBar() {
        let text = "gv_text = |a \\| b|.\n\" NOTE after the template\ngv_y = |z|.\n"
        XCTAssertTrue(isComment("NOTE", in: text, .abap))
    }

    func testAsciiDocUnpairedBacktickStopsAtTheLineEnd() {
        let text = "A lone ` backtick here.\n\n// NOTE a comment line\n\nAnother ` one.\n"
        XCTAssertTrue(isComment("NOTE", in: text, .asciidoc))
    }

    func testCOBOLLiteralContinuedWithADashLineDoesNotRunOn() {
        let text = """
                   01  WS-LONG  PIC X(60) VALUE "A literal that is too long
              -    " to fit on one line".
              *> NOTE the next paragraph
                   01  WS-NEXT  PIC X VALUE "N".

            """
        XCTAssertTrue(isComment("NOTE", in: text, .cobol))
    }

    func testCoffeeScriptEscapedQuoteDoesNotEndTheString() {
        let text = "single = 'it\\'s fine'\n# NOTE after the string\nother = 'x'\n"
        XCTAssertTrue(isComment("NOTE", in: text, .coffeescript))
    }

    func testElixirCharLiteralQuoteOpensNoString() {
        let text = "char = ?\"\n# NOTE after the char literal\nname = \"x\"\n"
        XCTAssertTrue(isComment("NOTE", in: text, .elixir))
    }

    func testElixirHeredocDocIsAStringNotAComment() {
        let text = "@moduledoc \"\"\"\n## Examples\n\"\"\"\n"
        XCTAssertFalse(isComment("Examples", in: text, .elixir))
    }
}

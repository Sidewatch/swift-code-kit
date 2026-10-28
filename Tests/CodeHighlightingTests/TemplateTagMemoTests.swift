//
//  TemplateTagMemoTests.swift
//  CodeHighlightingTests
//
//  A text's template tags: the ones the regex finds, searched for once per version of the text, and not at all in a
//  range with no tag opening.
//
//  Created by David Sherlock on 10/29/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation
import XCTest

@testable import CodeHighlighting

final class TemplateTagMemoTests: XCTestCase {
    private func units(_ text: String) -> [UInt16] { Array(text.utf16) }
    private func whole(_ text: String) -> [NSRange] { [NSRange(location: 0, length: (text as NSString).length)] }

    /// The tags found in a contiguous copy are the tags the regex finds in the text itself.
    func testTheTagsAreTheOnesTheRegexFinds() {
        let text = "<div>{{ name }}</div>\n<# if ( ok ) { #><p>{{{ raw }}}</p><# } #>\n"
        var memo = TemplateTagMemo()
        let found = memo.tags(within: whole(text), units: units(text), generation: 1)
        let regex = TreeSitterHighlighter.templateTagRanges(in: text as NSString, within: whole(text))
        XCTAssertEqual(found.code, regex.code)
        XCTAssertEqual(found.expressions, regex.expressions)
        XCTAssertEqual(found.all, regex.all)
        XCTAssertEqual(found.all.count, 4)
    }

    /// A text with no `<#` and no `{{` runs no search at all: every tag begins with one.
    func testATextWithNoTagOpeningRunsNoSearch() {
        let text = "<p>hello { world } # not a tag</p>\n"
        var memo = TemplateTagMemo()
        let found = memo.tags(within: whole(text), units: units(text), generation: 1)
        XCTAssertTrue(found.all.isEmpty)
        XCTAssertEqual(memo.searches, 0)
    }

    /// One version of the text is searched once, however often a pass asks; a new version is searched again.
    func testOneVersionIsSearchedOnce() {
        let text = "<p>{{ a }}</p>\n"
        var memo = TemplateTagMemo()
        for _ in 0..<3 { _ = memo.tags(within: whole(text), units: units(text), generation: 7) }
        XCTAssertEqual(memo.searches, 1)
        _ = memo.tags(within: whole(text), units: units(text), generation: 8)
        XCTAssertEqual(memo.searches, 2, "an edit makes a new version")
    }

    /// Of several ranges, only those holding an opening are searched, and what they hold is what the regex finds.
    func testARangeWithoutAnOpeningIsPassedOver() {
        let text = "<p>plain</p><p>{{ b }}</p>"
        let ranges = [NSRange(location: 0, length: 12), NSRange(location: 12, length: 14)]
        XCTAssertFalse(TreeSitterHighlighter.mayHoldTemplateTag(units(text), in: ranges[0]))
        XCTAssertTrue(TreeSitterHighlighter.mayHoldTemplateTag(units(text), in: ranges[1]))
        let found = TreeSitterHighlighter.templateTagRanges(inUnits: units(text), within: ranges)
        XCTAssertTrue(found.searched)
        XCTAssertEqual(found.tags.all, TreeSitterHighlighter.templateTagRanges(in: text as NSString, within: ranges).all)
    }
}

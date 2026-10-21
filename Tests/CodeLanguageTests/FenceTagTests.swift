//
//  FenceTagTests.swift
//  CodeLanguageTests
//
//  A fence tag names a language by its name or its extension.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import CodeLanguage

/// `Language(fenceTag:)`.
final class FenceTagTests: XCTestCase {
    func testATagIsALanguageNameOrAnExtension() {
        XCTAssertEqual(Language(fenceTag: "python"), .python, "a name the extension map does not have")
        XCTAssertEqual(Language(fenceTag: "rust"), .rust)
        XCTAssertEqual(Language(fenceTag: "py"), .python, "an extension")
        XCTAssertEqual(Language(fenceTag: " JavaScript "), .javascript, "trimmed, any case")
        XCTAssertEqual(Language(fenceTag: "python title=\"a.py\""), .python, "the first word only")
        XCTAssertEqual(Language(fenceTag: "ts{.numbered}"), .typescript)
    }

    func testATagNamingNothingIsNil() {
        XCTAssertNil(Language(fenceTag: ""))
        XCTAssertNil(Language(fenceTag: "notalanguage"))
        XCTAssertNil(Language(fenceTag: "plaintext"), "plain text is no language to colour")
    }
}

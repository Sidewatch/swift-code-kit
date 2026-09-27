//
//  FileSymbolTests.swift
//  CodeLanguageTests
//
//  A file's glyph: dotfiles and non-code kinds first, then its language's.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import CodeLanguage

final class FileSymbolTests: XCTestCase {
    func testDotfilesKindsAndLanguagesInThatOrder() {
        XCTAssertEqual(Language.symbolName(forFilename: ".env"), "key")
        XCTAssertEqual(Language.symbolName(forFilename: ".env.local"), "key")
        XCTAssertEqual(Language.symbolName(forFilename: ".gitignore"), "eye.slash")
        XCTAssertEqual(Language.symbolName(forFilename: "Photo.JPG"), "photo", "the extension is case-folded")
        XCTAssertEqual(Language.symbolName(forFilename: "yarn.lock"), "lock")
        XCTAssertEqual(Language.symbolName(forFilename: "main.swift"), Language.swift.symbolName)
        XCTAssertEqual(Language.symbolName(forExtension: "pdf"), "doc.fill")
        XCTAssertNil(Language.symbolName(forKindExtension: "swift"))
    }
}

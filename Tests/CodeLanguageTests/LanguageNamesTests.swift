//
//  LanguageNamesTests.swift
//  CodeLanguageTests
//
//  The names a language is detected from, enumerated — and every one of them detects back to it.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import CodeLanguage

final class LanguageNamesTests: XCTestCase {
    func testNamesRoundTripThroughDetection() {
        for language in Language.allCases {
            let names = Language.names(for: language)
            for ext in names.extensions {
                XCTAssertEqual(Language.detect(filename: "sample." + ext), language, "*.\(ext) should detect as \(language.rawValue)")
            }
            for name in names.filenames {
                XCTAssertEqual(Language.detect(filename: name), language, "\(name) should detect as \(language.rawValue)")
            }
        }
    }

    func testNamesAreTheWholeTable() {
        // Every entry of both tables is reachable through some language's names, so a caller
        // enumerating names(for:) over the languages it cares about cannot silently miss one.
        let extensions = Set(Language.allCases.flatMap { Language.names(for: $0).extensions })
        let filenames = Set(Language.allCases.flatMap { Language.names(for: $0).filenames })
        XCTAssertEqual(extensions.count, Set(Language.extensionMap.keys).union(Language.compoundExtensionMap.keys).count)
        XCTAssertEqual(filenames, Set(Language.filenameMap.keys))
        XCTAssertTrue(Language.names(for: .toml).extensions.contains("toml"))
        XCTAssertTrue(Language.names(for: .ini).filenames.contains(".npmrc"))
        XCTAssertTrue(Language.names(for: .plist).extensions.contains("entitlements"))
        XCTAssertTrue(Language.names(for: .systemd).extensions.contains("timer"))
    }
}

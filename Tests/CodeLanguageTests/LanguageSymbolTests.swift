//
//  LanguageSymbolTests.swift
//  CodeLanguageTests
//
//  Every language has an SF Symbol that resolves, in the category it belongs to.
//
//  Created by David Sherlock on 9/24/26.
//

import XCTest
import AppKit
@testable import CodeLanguage

final class LanguageSymbolTests: XCTestCase {
    /// A guessed symbol name renders nothing, silently — so every one is resolved here.
    func testEveryLanguageSymbolResolves() {
        for l in Language.allCases {
            XCTAssertNotNil(NSImage(systemSymbolName: l.symbolName, accessibilityDescription: nil), "\(l): \(l.symbolName)")
        }
    }

    func testCategories() {
        XCTAssertEqual(Language.swift.symbolName, "swift")
        XCTAssertEqual(Language.php.symbolName, "chevron.left.forwardslash.chevron.right")
        XCTAssertEqual(Language.html.symbolName, "globe")
        XCTAssertEqual(Language.scss.symbolName, "paintbrush")
        XCTAssertEqual(Language.json.symbolName, "curlybraces")
        XCTAssertEqual(Language.yaml.symbolName, "slider.horizontal.3")
        XCTAssertEqual(Language.makefile.symbolName, "hammer")
        XCTAssertEqual(Language.dockerfile.symbolName, "shippingbox")
        XCTAssertEqual(Language.terraform.symbolName, "server.rack")
        XCTAssertEqual(Language.csv.symbolName, "tablecells")
        XCTAssertEqual(Language.markdown.symbolName, "doc.richtext")
        XCTAssertEqual(Language.bash.symbolName, "terminal")
        XCTAssertEqual(Language.sql.symbolName, "cylinder")
        XCTAssertEqual(Language.mermaid.symbolName, "point.3.connected.trianglepath.dotted")
        XCTAssertEqual(Language.glsl.symbolName, "cpu")
        XCTAssertEqual(Language.r.symbolName, "function")
        XCTAssertEqual(Language.gitignore.symbolName, "arrow.triangle.branch")
        XCTAssertEqual(Language.diff.symbolName, "plus.forwardslash.minus")
        XCTAssertEqual(Language.log.symbolName, "list.bullet.rectangle")
        XCTAssertEqual(Language.plainText.symbolName, "doc.text")
        XCTAssertEqual(Language.dotenv.symbolName, "key")
    }
}

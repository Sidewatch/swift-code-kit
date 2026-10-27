//
//  LuauBuiltinsTests.swift
//  CodeHighlightingTests
//
//  Luau's built-in completions are Luau's own (luau.org/library), not Lua 5.4's.
//
//  Created by David Sherlock on 10/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import CodeLanguage
import XCTest

@testable import CodeHighlighting

final class LuauBuiltinsTests: XCTestCase {
    private func names(_ language: Language) -> Set<String> { Set(LanguageBuiltins.completions(for: language).map(\.text)) }

    func testLuauHasItsOwnLibraryAndNoneOfWhatItDropped() {
        let luau = names(.luau)
        for word in ["continue", "typeof", "split", "clamp", "round", "noise", "freeze", "clone", "bit32", "buffer", "vector", "readu32"] {
            XCTAssertTrue(luau.contains(word), word)
        }
        for word in ["goto", "io", "load", "dofile", "loadstring", "collectgarbage", "getenv"] {
            XCTAssertFalse(luau.contains(word), "\(word) is Lua's, not Luau's")
        }
    }

    func testASignatureNamesItsLibrary() throws {
        let find = try XCTUnwrap(LanguageBuiltins.completions(for: .luau).first { $0.text == "find" })
        XCTAssertTrue(find.detail?.contains("table.find") == true, String(describing: find.detail))
    }

    func testLuaKeepsLua54s() {
        XCTAssertTrue(names(.lua).contains("goto"))
        XCTAssertFalse(names(.lua).contains("typeof"))
    }
}

//
//  HighlighterCacheTests.swift
//  CodeHighlightingTests
//
//  The shared highlighter cache: one highlighter per language and per custom definition, a cold
//  grammar never waited on, and a clear that really drops everything.
//
//  Created by David Sherlock on 10/13/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import CodeLanguage
@testable import CodeHighlighting

@MainActor
final class HighlighterCacheTests: XCTestCase {

    func testALanguageIsBuiltOnceAndShared() {
        let cache = HighlighterCache(colors: DefaultTokenColors())
        XCTAssertTrue(cache.highlighter(for: .plainText) === cache.highlighter(for: .plainText))
    }

    func testAColdGrammarIsNeverWaitedOnAndSaysWhenItIsReady() throws {
        let language = CodeLanguage.Language.lua
        try XCTSkipUnless(TreeSitterHighlighter.grammarBuilders[language] != nil)
        TreeSitterHighlighter.forgetGrammarForTesting(language)
        let cache = HighlighterCache(colors: DefaultTokenColors())
        let ready = expectation(description: "grammar ready")
        var reported: [CodeLanguage.Language] = []
        cache.onGrammarReady = {
            reported.append($0)
            ready.fulfill()
        }

        let standIn = cache.highlighter(for: language)
        XCTAssertFalse(standIn is TreeSitterHighlighter, "while the grammar compiles, a lower tier stands in")
        XCTAssertFalse(cache.highlighter(for: language) === standIn, "the stand-in is returned, never cached")
        wait(for: [ready], timeout: 10)
        XCTAssertEqual(reported, [language], "one report, for the language that was asked for")

        let settled = cache.highlighter(for: language)
        XCTAssertFalse(settled === standIn)
        XCTAssertTrue(cache.highlighter(for: language) === settled, "once ready, the highlighter is cached")
    }

    func testOneCustomDefinitionSharesAHighlighterAndAChangedOneDoesNot() {
        let cache = HighlighterCache(colors: DefaultTokenColors())
        let def = CustomLanguageDefinition(name: "DSL", extensions: ["dsl"], keywords: ["begin"])
        let first = cache.highlighter(for: def)
        XCTAssertTrue(cache.highlighter(for: def) === first)
        var changed = def
        changed.keywords = ["end"]
        XCTAssertFalse(cache.highlighter(for: changed) === first, "two files both named DSL but different must not share")
    }

    func testClearDropsEveryHighlighter() {
        let cache = HighlighterCache(colors: DefaultTokenColors())
        let def = CustomLanguageDefinition(name: "DSL", extensions: ["dsl"])
        let builtIn = cache.highlighter(for: .plainText)
        let custom = cache.highlighter(for: def)
        cache.clear()
        XCTAssertFalse(cache.highlighter(for: .plainText) === builtIn)
        XCTAssertFalse(cache.highlighter(for: def) === custom)
    }
}

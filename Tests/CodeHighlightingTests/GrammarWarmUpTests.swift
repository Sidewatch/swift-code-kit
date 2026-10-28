//
//  GrammarWarmUpTests.swift
//  CodeHighlightingTests
//
//  The launch warm-up and an on-demand request for the same grammar never compile it twice.
//
//  Created by David Sherlock on 10/3/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import CodeLanguage
@testable import CodeHighlighting

/// The app warms every grammar on a background thread at launch while the restored tabs ask for
/// theirs on the main thread. A request that arrives while its grammar is compiling must wait for
/// that compile, not run a second one on the main thread.
final class GrammarWarmUpTests: XCTestCase {

    func testARequestDuringAnInFlightCompileWaitsForIt() throws {
        let language = CodeLanguage.Language.kotlin
        try XCTSkipUnless(TreeSitterHighlighter.grammarBuilders[language] != nil)
        // Catch the background compile in flight; a compile can finish before the first look, so
        // try a few times.
        for _ in 0..<20 {
            TreeSitterHighlighter.forgetGrammarForTesting(language)
            let before = TreeSitterHighlighter.grammarCompiles
            let finished = DispatchSemaphore(value: 0)
            Thread.detachNewThread {
                _ = TreeSitterHighlighter.grammar(for: language)
                finished.signal()
            }
            let deadline = Date().addingTimeInterval(2)
            while !TreeSitterHighlighter.isCompilingGrammar(language), Date() < deadline { usleep(50) }
            guard TreeSitterHighlighter.isCompilingGrammar(language) else { finished.wait(); continue }
            XCTAssertNotNil(TreeSitterHighlighter.grammar(for: language), "the waiting request gets the grammar")
            finished.wait()
            XCTAssertEqual(TreeSitterHighlighter.grammarCompiles - before, 1, "one compile, shared, not two")
            return
        }
        XCTFail("never caught the compile in flight")
    }

    func testTheWarmUpCompilesThePrioritisedLanguagesAndEveryOther() {
        TreeSitterHighlighter.warmUpGrammars(prioritizing: [.swift, .swift])
        for language in TreeSitterHighlighter.grammarBuilders.keys {
            XCTAssertFalse(TreeSitterHighlighter.isCompilingGrammar(language))
        }
        XCTAssertTrue(TreeSitterHighlighter.supports(.swift))
    }

    /// Opening a file must not block on a compile: the host asks whether the grammar is ready, and
    /// otherwise compiles it in the background and hears back on the main queue.
    @MainActor
    func testABackgroundCompileReportsReadinessWithoutBlocking() throws {
        let language = CodeLanguage.Language.lua
        try XCTSkipUnless(TreeSitterHighlighter.grammarBuilders[language] != nil)
        TreeSitterHighlighter.forgetGrammarForTesting(language)
        XCTAssertFalse(TreeSitterHighlighter.isGrammarReady(language), "forgotten: not ready")
        XCTAssertTrue(TreeSitterHighlighter.isGrammarReady(.plainText), "no grammar at all: nothing to wait for")
        let done = expectation(description: "compiled")
        TreeSitterHighlighter.compileGrammarInBackground(language) {
            XCTAssertTrue(Thread.isMainThread)
            done.fulfill()
        }
        wait(for: [done], timeout: 10)
        XCTAssertTrue(TreeSitterHighlighter.isGrammarReady(language))
    }

    /// A grammar a highlight cannot wait for (an injected language, a fenced block): asked for before it is compiled,
    /// it answers at once and compiles in the background, once however often it is asked, and says when it lands.
    @MainActor
    func testARequestNeverCompilesOnTheCallingThreadAndSaysWhenItLands() throws {
        let language = CodeLanguage.Language.ruby
        try XCTSkipUnless(TreeSitterHighlighter.grammarBuilders[language] != nil)
        TreeSitterHighlighter.forgetGrammarForTesting(language)
        var landings = 0
        let landed = expectation(description: "landed")
        TreeSitterHighlighter.onRequestedGrammarReady = {
            if $0 == language {
                landings += 1
                landed.fulfill()
            }
        }
        defer { TreeSitterHighlighter.onRequestedGrammarReady = nil }
        let waitsBefore = TreeSitterHighlighter.mainThreadGrammarWaitsForTesting
        XCTAssertFalse(TreeSitterHighlighter.requestGrammar(language), "not compiled: no wait, no grammar yet")
        XCTAssertFalse(TreeSitterHighlighter.requestGrammar(language), "asked again while it compiles")
        XCTAssertTrue(TreeSitterHighlighter.isRequestedForTesting(language))
        wait(for: [landed], timeout: 30)
        XCTAssertEqual(landings, 1, "one compile, one landing")
        XCTAssertEqual(TreeSitterHighlighter.mainThreadGrammarWaitsForTesting, waitsBefore, "the main thread never compiled or waited")
        XCTAssertTrue(TreeSitterHighlighter.requestGrammar(language), "ready now")
        XCTAssertFalse(TreeSitterHighlighter.isRequestedForTesting(language))
        XCTAssertTrue(TreeSitterHighlighter.requestGrammar(.plainText), "no grammar at all: nothing to wait for")
    }

    /// The main thread asking for a grammar not compiled yet is counted (it compiles, or waits for a compile): the
    /// seam a host checks its promise against. A grammar already compiled, or a language with none, is not.
    @MainActor
    func testTheMainThreadAskingForAnUncompiledGrammarIsCounted() throws {
        let language = CodeLanguage.Language.go
        try XCTSkipUnless(TreeSitterHighlighter.grammarBuilders[language] != nil)
        TreeSitterHighlighter.forgetGrammarForTesting(language)
        let before = TreeSitterHighlighter.mainThreadGrammarWaitsForTesting
        _ = TreeSitterHighlighter.grammar(for: language)
        XCTAssertEqual(TreeSitterHighlighter.mainThreadGrammarWaitsForTesting, before + 1)
        _ = TreeSitterHighlighter.grammar(for: language)
        _ = TreeSitterHighlighter.grammar(for: .plainText)
        XCTAssertEqual(TreeSitterHighlighter.mainThreadGrammarWaitsForTesting, before + 1, "compiled now, or none at all: no wait")
    }
}

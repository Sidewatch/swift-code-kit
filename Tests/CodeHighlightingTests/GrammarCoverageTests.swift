//
//  GrammarCoverageTests.swift
//  CodeHighlightingTests
//
//  Grammar coverage read from the compiled grammar, against what a parse produced.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import CodeLanguage
@testable import CodeHighlighting

final class GrammarCoverageTests: XCTestCase {
    func testTheGrammarsOwnSymbolsAreTheDefinition() throws {
        let c = try XCTUnwrap(TreeSitterHighlighter.grammarCoverage(of: "{}", language: .json))
        XCTAssertTrue(c.nodes.isSuperset(of: ["object", "array", "pair", "string", "number", "true", "false", "null"]), "\(c.nodes)")
        XCTAssertTrue(c.tokens.isSuperset(of: ["{", "}", "[", "]", ":", ","]), "\(c.tokens)")
        XCTAssertFalse(c.nodes.contains(where: { $0.hasPrefix("_") }), "hidden rules never stand in a tree")
        XCTAssertFalse(c.nodes.contains("ERROR"))
    }

    func testWhatTheTextUsesIsSeenAndTheRestIsMissing() throws {
        let c = try XCTUnwrap(TreeSitterHighlighter.grammarCoverage(of: #"{"a": [1, true]}"#, language: .json))
        XCTAssertTrue(c.seenNodes.isSuperset(of: ["document", "object", "pair", "string", "array", "number", "true"]), "\(c.seenNodes)")
        XCTAssertTrue(c.missingNodes.contains("false") && c.missingNodes.contains("null"), "\(c.missingNodes)")
        XCTAssertFalse(c.missingNodes.contains("array"))
        XCTAssertTrue(c.seenTokens.isSuperset(of: ["{", "[", ":", ","]))
        XCTAssertEqual(c.errors, 0)
        XCTAssertGreaterThan(c.nodeShare, 0.3)
        XCTAssertLessThan(c.nodeShare, 1)
    }

    func testAFullCoverageTextMissesNothingAndAMalformedOneCountsItsErrors() throws {
        let full = try XCTUnwrap(
            TreeSitterHighlighter.grammarCoverage(of: #"{"a": [1, "s\n", true, false, null, {}]}"#, language: .json))
        XCTAssertFalse(
            full.missingNodes.contains("false") || full.missingNodes.contains("null") || full.missingNodes.contains("escape_sequence"))
        let broken = try XCTUnwrap(TreeSitterHighlighter.grammarCoverage(of: #"{"a": [1, }"#, language: .json))
        XCTAssertGreaterThan(broken.errors, 0)
        XCTAssertNil(TreeSitterHighlighter.grammarCoverage(of: "x", language: .plainText))
    }
}

//
//  DeepStructureTests.swift
//  CodeHighlightingTests
//
//  Documents nested tens of thousands of levels deep: the grammars parse them, and the readers
//  must turn them into values without following the nesting down the stack.
//
//  Created by David Sherlock on 10/9/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import DataConverter
@testable import CodeHighlighting

final class DeepStructureTests: XCTestCase {
    /// How many levels of mappings and sequences `value` holds.
    func depth(_ value: StructuredValue?) -> Int {
        var current = value
        var levels = 0
        while let v = current {
            switch v {
            case .mapping(let pairs): current = pairs.first?.value
            case .sequence(let items): current = items.first
            default: current = nil
            }
            if current != nil { levels += 1 }
        }
        return levels
    }

    func testFiftyThousandNestedYAMLSequencesAreReadToTheDepthLimit() throws {
        try XCTSkipUnless(TreeSitterHighlighter.supports(.yaml))
        let text = "a: " + String(repeating: "[", count: 50_000) + String(repeating: "]", count: 50_000) + "\n"
        let value = YAMLStructure.value(of: text)
        XCTAssertNotNil(value)
        XCTAssertLessThanOrEqual(depth(value), StructureDepth.limit + 1)
        XCTAssertGreaterThan(depth(value), 100, "the levels within the limit are read as nesting")
    }

    func testTenThousandNestedTOMLArraysAreReadToTheDepthLimit() throws {
        try XCTSkipUnless(TreeSitterHighlighter.supports(.toml))
        let text = "a = " + String(repeating: "[", count: 10_000) + String(repeating: "]", count: 10_000) + "\n"
        let value = TOMLStructure.value(of: text)
        XCTAssertNotNil(value)
        XCTAssertLessThanOrEqual(depth(value), StructureDepth.limit + 1)
    }

    func testFiftyThousandNestedXMLElementsAreReadToTheDepthLimit() throws {
        try XCTSkipUnless(TreeSitterHighlighter.supports(.xml))
        let text = String(repeating: "<a>", count: 50_000) + "x" + String(repeating: "</a>", count: 50_000)
        let value = XMLStructure.value(of: text)
        XCTAssertNotNil(value)
        XCTAssertLessThanOrEqual(depth(value), StructureDepth.limit + 1)
        let plist =
            "<?xml version=\"1.0\"?><plist version=\"1.0\">" + String(repeating: "<array>", count: 20_000) + "<string>x</string>"
            + String(repeating: "</array>", count: 20_000) + "</plist>"
        let plistValue = PlistStructure.value(of: plist)
        XCTAssertNotNil(plistValue)
        XCTAssertLessThanOrEqual(depth(plistValue), StructureDepth.limit + 1)
    }
}

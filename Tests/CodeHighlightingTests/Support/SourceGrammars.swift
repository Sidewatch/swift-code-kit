//
//  SourceGrammars.swift
//  CodeHighlightingTests
//
//  Grammars built from the vendored query files, for tests.
//
//  Created by David Sherlock on 10/29/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import CodeLanguage
import Foundation
import SwiftTreeSitter
import XCTest

@testable import CodeHighlighting

/// Grammars built from the vendored query files under `Grammars/`, with the flags their builders set: a test builds
/// the grammars it reaches from the source tree rather than from query bundles.
enum SourceGrammars {
    static let folder = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Grammars")

    /// `language`'s grammar from `highlights` and `injections` (query files under `Grammars/`), `lead` before them.
    static func grammar(
        _ language: CodeLanguage.Language, highlights: [String], injections: [String] = [], lead: String = "", templateTags: Bool = false
    ) throws -> TreeSitterHighlighter.Grammar {
        let ts = try XCTUnwrap(TreeSitterHighlighter.tsLanguage(for: language), "no grammar for \(language)")
        func read(_ file: String) throws -> String { try String(contentsOf: folder.appendingPathComponent(file), encoding: .utf8) }
        let highlightSource = try lead + highlights.map(read).joined(separator: "\n")
        let injectionSource = try injections.map(read).joined(separator: "\n")
        return .init(
            language: ts, highlights: try Query(language: ts, data: Data(TreeSitterHighlighter.prunedQuerySource(highlightSource).utf8)),
            injections: injectionSource.isEmpty ? nil : try Query(language: ts, data: Data(injectionSource.utf8)),
            templateTags: templateTags)
    }

    /// HTML as its builder makes it: injections, and its text scanned for template tags.
    static func html() throws -> TreeSitterHighlighter.Grammar {
        try grammar(
            .html, highlights: ["tree-sitter-html/queries/highlights.scm"], injections: ["tree-sitter-html/queries/injections.scm"],
            templateTags: true)
    }

    /// JavaScript, its identifiers given a colour of their own so a coloured script reads as one.
    static func javascript() throws -> TreeSitterHighlighter.Grammar {
        try grammar(.javascript, highlights: ["tree-sitter-javascript/queries/highlights.scm"], lead: "(identifier) @identifier.plain\n")
    }
}

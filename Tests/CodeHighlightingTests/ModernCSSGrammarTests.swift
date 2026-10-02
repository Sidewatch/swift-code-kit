//
//  ModernCSSGrammarTests.swift
//  CodeHighlightingTests
//
//  The vendored CSS grammar parses the CSS browsers ship today.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import CodeLanguage
@testable import CodeHighlighting

/// Upstream tree-sitter-css (v0.25.0, also its main) produced ERROR nodes on every one of these, and a
/// parse error spoils the colours around it: the corpus's CSS showcase had 512 of them. The local patch
/// (`Grammars/tree-sitter-css/sidewatch-modern-css.patch`) fixes them; this pins it, so re-vendoring an
/// unpatched upstream fails here.
final class ModernCSSGrammarTests: XCTestCase {
    static let modern: [(String, String)] = [
        ("range media query", "@media (400px <= width <= 700px) { .n { display: block; } }"),
        ("range in a nested media query", ".a { @media (width < 600px) { display: block; } }"),
        ("named container query", "@container sidebar (min-width: 400px) { .c { display: flex; } }"),
        ("container style() query", "@container style(--theme: dark) { .c { color: white; } }"),
        ("container scroll-state() query", "@container scroll-state(stuck: top) { .s { top: 0; } }"),
        ("dotted layer name", "@layer reset.base { a { x: y; } }"),
        ("import with layer() and supports()", "@import url(x.css) layer(theme) supports(display: grid) screen;"),
        ("page pseudo selector", "@page :first { margin: 1in; }"),
        ("@function rule", "@function --negate(--value <number>) returns <number> { result: calc(-1 * var(--value)); }"),
        ("typed attr()", ".m { width: attr(data-w type(<length>), 0px); }"),
        ("attribute case flag", "a[href$=\".pdf\" i] { x: y; }"),
        ("nesting selector at the end", ".a { .dense & { padding: 0; } }"),
        ("unquoted url", "a { background: url(../img/a.png); mask: url(#mask); }"),
        ("escaped and Unicode class names", ".sm\\:flex, .w-1\\/2, #\\#hash, .日本語 { margin: 0; }"),
        ("spaced !important", "a { color: red ! important; }"),
        ("fractional keyframe", "@keyframes k { 24.99% { opacity: 0; } }"),
        ("empty statements", "a { color: red;; margin: 0; }"),
        ("string line continuation", ".e::before { content: \"a \\\ncontinued\"; }"),
    ]

    func testModernCSSParsesWithoutErrors() {
        var failing: [String] = []
        for (name, css) in Self.modern where TreeSitterHighlighter.parseErrorCount(in: css, language: .css) != 0 {
            failing.append(name)
        }
        XCTAssertEqual(failing, [])
    }
}

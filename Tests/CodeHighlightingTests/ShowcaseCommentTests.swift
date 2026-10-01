//
//  ShowcaseCommentTests.swift
//  CodeHighlightingTests
//
//  The corpus's language showcases through the regex tier: every comment-only line painted as one.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

/// Sidewatch's test corpus (`Sidewatch/test-files`, cloned beside this package's family as
/// `../../TestFiles`, or `SIDEWATCH_CORPUS`) holds one complete showcase per language. Through the
/// regex tier — what every language without a tree-sitter grammar is painted with — a line that holds
/// only a line comment must start in the comment colour and be mostly that colour. A string that
/// leaks past its end (a stray quote, an unknown escape or literal form) paints the comments after it
/// as strings, and fails here naming the file and line. Skipped when the corpus is not cloned.
/// `SHOWCASE_LANGUAGES=haskell,nim` narrows it.
@MainActor
final class ShowcaseCommentTests: XCTestCase {
    private struct OneColourPerKind: TokenColorProviding {
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor { kind == .comment ? .systemGreen : .systemRed }
    }

    private var corpus: URL {
        if let path = ProcessInfo.processInfo.environment["SIDEWATCH_CORPUS"] { return URL(fileURLWithPath: path) }
        return URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../../TestFiles").standardized
    }

    /// Lines that start with the comment token but are not comments: Markdown headings inside a
    /// docstring are STRING content in Julia (`\"\"\"…\"\"\"`) and Elixir (`@moduledoc \"\"\"…\"\"\"`), and
    /// painting them as strings is right. Keyed by language folder and the line's trimmed text.
    static let notComments: [String: Set<String>] = [
        "julia": ["# Arguments", "# Examples"],
        "elixir": ["## Examples"],
    ]

    /// Languages the editor paints through another tier, so the regex tier is not what a reader sees.
    static let otherTier: Set<Language> = [.vue, .svelte, .astro]

    func testEveryShowcasesCommentLinesArePaintedAsComments() throws {
        let root = corpus.appendingPathComponent("languages")
        guard FileManager.default.fileExists(atPath: root.path) else { throw XCTSkip("corpus not cloned at \(root.path)") }
        let only = ProcessInfo.processInfo.environment["SHOWCASE_LANGUAGES"].map { Set($0.split(separator: ",").map(String.init)) }
        var failing: [String] = []
        let folders = (try FileManager.default.contentsOfDirectory(atPath: root.path)).sorted()
        for folder in folders where folder != "picker-only" && (only?.contains(folder) ?? true) {
            let dir = root.appendingPathComponent(folder)
            guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { continue }  // README.md
            for name in names where name != ".DS_Store" {
                let url = dir.appendingPathComponent(name)
                let language = Language.detect(for: url)
                guard !Self.otherTier.contains(language), TreeSitterHighlighter.grammar(for: language) == nil,
                    let text = try? String(contentsOf: url, encoding: .utf8)
                else { continue }
                let bad = unpaintedCommentLines(text, language, skipping: Self.notComments[folder] ?? [])
                if !bad.isEmpty { failing.append("\(folder)/\(name): lines \(bad.prefix(8).map(String.init).joined(separator: ", "))") }
            }
        }
        XCTAssertEqual(failing, [], "comment lines painted as something else")
    }

    /// 1-based lines that hold only a line comment but are not recognised (first glyph) or not
    /// mostly painted as one.
    private func unpaintedCommentLines(_ text: String, _ language: Language, skipping: Set<String>) -> [Int] {
        guard let token = language.lineCommentToken, !token.isEmpty else { return [] }
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: NSColor.black])
        SyntaxHighlighter(language: language, colors: OneColourPerKind())
            .highlight(storage, in: NSRange(location: 0, length: storage.length))
        let ns = storage.string as NSString
        var bad: [Int] = []
        var line = 1, pos = 0
        while pos < ns.length {
            let range = ns.lineRange(for: NSRange(location: pos, length: 0))
            let trimmed = ns.substring(with: range).trimmingCharacters(in: .whitespacesAndNewlines)
            // Org's `#+KEYWORD:` lines start with its comment token and are keywords, not comments.
            let orgKeyword = language == .org && trimmed.hasPrefix("#+")
            if trimmed.hasPrefix(token), !trimmed.hasPrefix("#!"), !skipping.contains(trimmed), !orgKeyword {
                var visible = 0, painted = 0, first = true, firstPainted = false
                for i in range.location..<NSMaxRange(range) {
                    guard let s = Unicode.Scalar(ns.character(at: i)), !CharacterSet.whitespacesAndNewlines.contains(s) else { continue }
                    let isComment = storage.attribute(.foregroundColor, at: i, effectiveRange: nil) as? NSColor == .systemGreen
                    if first { firstPainted = isComment; first = false }
                    visible += 1
                    if isComment { painted += 1 }
                }
                if !(firstPainted && painted * 2 >= visible) { bad.append(line) }
            }
            line += 1
            pos = NSMaxRange(range)
        }
        return bad
    }
}

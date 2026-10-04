//
//  RestructuredTextOutline.swift
//  CodeHighlighting
//
//  The section titles of a reStructuredText document, nested as the document nests them.
//
//  Created by David Sherlock on 10/4/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The section titles of a reStructuredText document: a line of text underlined (and optionally
/// overlined) with a run of one punctuation character at least as long as the text. reST has no
/// fixed levels — the first adornment style met is level 1, the next new one level 2, and so on —
/// so levels are assigned in order of first appearance, an overlined style distinct from the same
/// character underlined alone. Each title holds what follows it up to the next title of the same
/// or a higher level.
enum RestructuredTextOutline {
    /// The characters reST accepts as adornment.
    private static let adornments = Set("!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~")

    static func symbols(in text: String) -> [Symbol] {
        let ns = text as NSString
        guard ns.length > 0 else { return [] }
        let lines = OutlineLines(ns)
        let count = lines.starts.count
        /// Line `k` without its line break.
        func line(_ k: Int) -> String {
            let start = lines.starts[k]
            let end = k + 1 < count ? lines.starts[k + 1] : ns.length
            return ns.substring(with: NSRange(location: start, length: end - start)).trimmingCharacters(in: .newlines)
        }
        /// The adornment character when line `k` is a run of one (at least 3 long), else nil.
        func adornment(_ k: Int) -> Character? {
            guard k >= 0, k < count else { return nil }
            let l = line(k).trimmingCharacters(in: .whitespaces)
            guard l.count >= 3, let first = l.first, adornments.contains(first), l.allSatisfy({ $0 == first }) else { return nil }
            return first
        }

        var styles: [String] = []  // adornment styles in order of first appearance = levels
        var found: [(symbol: Symbol, level: Int, firstLine: Int)] = []
        var k = 0
        while k < count - 1 {
            let title = line(k)
            let trimmed = title.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, adornment(k) == nil, let under = adornment(k + 1),
                line(k + 1).trimmingCharacters(in: .whitespaces).count >= min(trimmed.count, 3)
            else { k += 1; continue }
            let over = adornment(k - 1) == under && (k < 2 || line(k - 2).trimmingCharacters(in: .whitespaces).isEmpty)
            // An underline-only title starts at the margin; only an overlined one may be indented.
            if !over, title.first?.isWhitespace == true { k += 1; continue }
            let style = (over ? "o" : "u") + String(under)
            if !styles.contains(style) { styles.append(style) }
            let level = styles.firstIndex(of: style)! + 1
            let start = lines.starts[k] + ((title as NSString).range(of: trimmed).location)
            let symbol = Symbol(
                name: trimmed, kind: .heading, range: NSRange(location: start, length: (trimmed as NSString).length), line: k + 1)
            found.append((symbol, level, over ? k - 1 : k))
            k += 2
        }
        return found.indices.map { i in
            let s = found[i]
            let start = lines.starts[s.firstLine]
            var end = ns.length
            for next in found[(i + 1)...] where next.level <= s.level {
                end = lines.starts[next.firstLine]
                break
            }
            return Symbol(
                name: s.symbol.name, kind: .heading, range: s.symbol.range, line: s.symbol.line,
                scopeRange: NSRange(location: start, length: end - start))
        }
    }
}

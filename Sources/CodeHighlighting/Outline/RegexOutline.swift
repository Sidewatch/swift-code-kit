//
//  RegexOutline.swift
//  CodeHighlighting
//
//  Outlines for languages without a tree-sitter grammar: a table of declaration patterns per
//  language, matched line by line in one pass.
//
//  Created by David Sherlock on 10/4/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation
import CodeLanguage

/// Outlines for languages without a tree-sitter grammar: a table of declaration patterns per
/// language (`sub name`, `defmodule Name`, `name <- function`, `\section{Title}`…), matched in one
/// pass over the text. Each table says how its declarations nest:
///
/// - ``Scoping/indentation``: a declaration holds the lines indented under it (Elixir, Julia,
///   Nim, Haskell, F#, the `end`-terminated languages written the usual way);
/// - ``Scoping/braces``: a declaration holds the `{ … }` block that follows its name (Perl, Raku,
///   R, Zig, the C family's shader languages), strings and comments skipped while counting;
/// - ``Scoping/levels``: each pattern has a level and holds everything up to the next pattern of
///   the same or a higher level (LaTeX sections, INI sections over their keys, diff files over
///   their hunks);
/// - ``Scoping/flat``: no nesting (labels, Makefile targets, SQL objects).
///
/// Regex outlines are approximate by design — a declaration inside a block comment or a heredoc
/// is listed — which is the trade every editor's non-grammar outline makes.
public enum RegexOutline {
    /// How a table's declarations nest.
    public enum Scoping: Sendable { case flat, indentation, braces, levels }

    /// Which physical lines continue the line above, so a match on one is part of a value, not a
    /// declaration.
    enum Continuation: Sendable {
        /// After a line ending in an odd run of backslashes; a `#` or `!` comment never continues
        /// (`.properties`).
        case backslash
        /// A line indented deeper than the key above it, until the next section (INI's multi-line
        /// values, as configparser reads them); `keyLevel` is the keys' rule level.
        case deeperIndent(keyLevel: Int)
    }

    /// One declaration pattern: exactly ONE capturing group, the name.
    struct Rule: Sendable {
        let pattern: String
        let kind: SymbolKind
        let level: Int
    }

    /// One language's patterns and how they nest.
    struct Table: Sendable {
        let rules: [Rule]
        let scoping: Scoping
        /// The line comment that ends brace counting on a line (`//`, `#`, `%`, `--`).
        var lineComment: String? = nil
        /// Whether `/* … */` is skipped while counting braces.
        var blockComments = false
        /// Whether quotes, backticks and brackets are stripped from names (`"aws_instance" "web"`).
        var cleanNames = false
        /// The lines whose matches are part of a value above them.
        var continuation: Continuation? = nil
        /// A name as the format reads it (`.properties` escapes resolved), so the outline names a
        /// key as the structure tree does.
        var readName: (@Sendable (String) -> String)? = nil
    }

    /// Whether `language` has a regex outline.
    public static func supports(_ language: Language) -> Bool { tables[language] != nil }

    /// The outline symbols of `text`, in document order, each scoped per its table. Empty for a
    /// language without a table.
    public static func symbols(in text: String, language: Language) -> [Symbol] {
        guard let table = tables[language], let regex = compiled(language, table) else { return [] }
        let ns = text as NSString
        let length = ns.length
        guard length > 0 else { return [] }
        var buffer = [unichar](repeating: 0, count: length)
        ns.getCharacters(&buffer, range: NSRange(location: 0, length: length))

        // Every declaration, in order: the match's line start, the name's range, its rule.
        var found: [(lineStart: Int, name: NSRange, rule: Rule)] = []
        let groups = table.rules.count
        for match in regex.matches(in: text, options: [], range: NSRange(location: 0, length: length)) {
            for g in 1...groups {
                let r = match.range(at: g)
                guard r.location != NSNotFound, r.length > 0 else { continue }
                found.append((match.range.location, r, table.rules[g - 1]))
                break
            }
        }
        guard !found.isEmpty else { return [] }

        var lineStarts = [0]
        lineStarts.reserveCapacity(length / 30)
        for i in 0..<length where buffer[i] == 0x0A { lineStarts.append(i + 1) }
        // Lines that continue a value above them declare nothing and end no indentation scope.
        var continued: Set<Int> = []
        if case .backslash = table.continuation { continued = backslashContinuedLines(lineStarts: lineStarts, buffer: buffer) }
        if let continuation = table.continuation {
            found = droppingContinued(found, continuation, continued: continued, buffer: buffer)
        }
        /// The 0-based line holding offset `o`.
        func lineIndex(of o: Int) -> Int {
            var lo = 0, hi = lineStarts.count - 1
            while lo < hi {
                let mid = (lo + hi + 1) / 2
                if lineStarts[mid] <= o { lo = mid } else { hi = mid - 1 }
            }
            return lo
        }

        var out: [Symbol] = []
        out.reserveCapacity(found.count)
        var levels: [Int] = []
        for item in found {
            var name = ns.substring(with: item.name).trimmingCharacters(in: .whitespaces)
            if table.cleanNames { name = cleaned(name) }
            if let readName = table.readName { name = readName(name) }
            guard !name.isEmpty else { continue }
            // Clauses of one definition written one after another (Erlang, Prolog) list once.
            if let last = out.last, last.name == name, last.kind == item.rule.kind, levels.last == item.rule.level { continue }
            let line = lineIndex(of: item.name.location)
            let scope: NSRange?
            switch table.scoping {
            case .flat, .levels: scope = nil  // levels are scoped below, once every symbol is known
            case .indentation: scope = indentationScope(line: line, lineStarts: lineStarts, buffer: buffer, continued: continued)
            case .braces: scope = braceScope(from: NSMaxRange(item.name), lineStart: item.lineStart, buffer: buffer, table: table)
            }
            out.append(Symbol(name: name, kind: item.rule.kind, range: item.name, line: line + 1, scopeRange: scope))
            levels.append(item.rule.level)
        }
        if table.scoping == .levels { return levelScoped(out, levels: levels, length: length, lineStarts: lineStarts) }
        return out
    }

    // MARK: - Continuation lines

    /// `found` without the matches on lines that continue a value above them.
    private static func droppingContinued(
        _ found: [(lineStart: Int, name: NSRange, rule: Rule)], _ continuation: Continuation, continued: Set<Int>, buffer: [unichar]
    ) -> [(lineStart: Int, name: NSRange, rule: Rule)] {
        func indent(at start: Int) -> Int {
            var i = start
            while i < buffer.count, buffer[i] == 0x20 || buffer[i] == 0x09 { i += 1 }
            return i - start
        }
        switch continuation {
        case .backslash:
            return found.filter { !continued.contains($0.lineStart) }
        case .deeperIndent(let keyLevel):
            var keyIndent: Int?
            return found.filter { item in
                let width = indent(at: item.lineStart)
                if let keyIndent, width > keyIndent { return false }
                keyIndent = item.rule.level >= keyLevel ? width : nil
                return true
            }
        }
    }

    /// The starts of the lines that continue the line above it: that line ends in an odd run of
    /// backslashes and is not itself a comment (a comment opens only a line no value continues).
    private static func backslashContinuedLines(lineStarts: [Int], buffer: [unichar]) -> Set<Int> {
        var out: Set<Int> = []
        var continues = false
        for (index, start) in lineStarts.enumerated() {
            if continues { out.insert(start) }
            var end = index + 1 < lineStarts.count ? lineStarts[index + 1] : buffer.count
            while end > start, buffer[end - 1] == 0x0A || buffer[end - 1] == 0x0D { end -= 1 }
            var first = start
            while first < end, buffer[first] == 0x20 || buffer[first] == 0x09 || buffer[first] == 0x0C { first += 1 }
            let comment = !continues && first < end && (buffer[first] == 0x23 || buffer[first] == 0x21)  // # !
            var slashes = 0
            while end - slashes > first, buffer[end - slashes - 1] == 0x5C { slashes += 1 }
            continues = !comment && slashes % 2 == 1
        }
        return out
    }

    // MARK: - Scopes

    /// A declaration's lines: from its own line to the line before the next non-blank line indented
    /// no deeper than it (a line in `continued` carries on a value, so it counts as blank).
    private static func indentationScope(line: Int, lineStarts: [Int], buffer: [unichar], continued: Set<Int>) -> NSRange? {
        let length = buffer.count
        func indent(_ l: Int) -> Int? {  // nil for a blank or continuation line
            guard !continued.contains(lineStarts[l]) else { return nil }
            var i = lineStarts[l], width = 0
            let end = l + 1 < lineStarts.count ? lineStarts[l + 1] : length
            while i < end {
                switch buffer[i] {
                case 0x20: width += 1
                case 0x09: width += 4
                case 0x0A, 0x0D: return nil
                default: return width
                }
                i += 1
            }
            return nil
        }
        guard let own = indent(line) else { return nil }
        var next = line + 1
        while next < lineStarts.count {
            if let width = indent(next), width <= own { break }
            next += 1
        }
        let start = lineStarts[line]
        let end = next < lineStarts.count ? lineStarts[next] : length
        return NSRange(location: start, length: max(0, end - start))
    }

    /// A declaration's `{ … }` block: the first `{` after its name (within three lines, before any
    /// `;` or `}`) to its matching `}`, strings and comments skipped. Nil when there is none.
    private static func braceScope(from nameEnd: Int, lineStart: Int, buffer: [unichar], table: Table) -> NSRange? {
        let length = buffer.count
        let comment = table.lineComment.map { Array($0.utf16) }
        var i = nameEnd
        var depth = 0
        var newlines = 0
        while i < length {
            let c = buffer[i]
            if let comment, c == comment[0], i + comment.count <= length,
                comment.indices.allSatisfy({ buffer[i + $0] == comment[$0] })
            {
                while i < length, buffer[i] != 0x0A { i += 1 }
                continue
            }
            if table.blockComments, c == 0x2F /* / */, i + 1 < length, buffer[i + 1] == 0x2A /* * */ {
                i += 2
                while i + 1 < length, !(buffer[i] == 0x2A && buffer[i + 1] == 0x2F) { i += 1 }
                i += 2
                continue
            }
            switch c {
            case 0x22, 0x27, 0x60:  // " ' ` — a literal on this line
                var j = i + 1
                while j < length, buffer[j] != c, buffer[j] != 0x0A {
                    if buffer[j] == 0x5C { j += 1 }  // backslash escape
                    j += 1
                }
                i = j < length && buffer[j] == c ? j + 1 : i + 1
                continue
            case 0x7B:  // {
                depth += 1
            case 0x7D:  // }
                if depth == 0 { return nil }
                depth -= 1
                if depth == 0 { return NSRange(location: lineStart, length: i + 1 - lineStart) }
            case 0x3B:  // ;
                if depth == 0 { return nil }
            case 0x0A:
                if depth == 0 {
                    newlines += 1
                    if newlines > 2 { return nil }
                }
            default: break
            }
            i += 1
        }
        return nil
    }

    /// Scopes for a levelled table: each symbol runs to the next one of the same or a higher level.
    private static func levelScoped(_ symbols: [Symbol], levels: [Int], length: Int, lineStarts: [Int]) -> [Symbol] {
        var out: [Symbol] = []
        out.reserveCapacity(symbols.count)
        for (i, s) in symbols.enumerated() {
            var end = length
            for j in (i + 1)..<symbols.count where levels[j] <= levels[i] {
                end = lineStarts[symbols[j].line - 1]
                break
            }
            let start = lineStarts[s.line - 1]
            out.append(
                Symbol(
                    name: s.name, kind: s.kind, range: s.range, line: s.line,
                    scopeRange: NSRange(location: start, length: max(s.range.length, end - start))))
        }
        return out
    }

    /// A name without its quotes, backticks or brackets, and with its spaces collapsed.
    private static func cleaned(_ name: String) -> String {
        let stripped = name.filter { !"\"`[]'".contains($0) }
        return stripped.split(whereSeparator: { $0 == " " || $0 == "\t" }).joined(separator: " ")
    }

    // MARK: - Compiling

    private nonisolated(unsafe) static var cache: [Language: NSRegularExpression] = [:]
    private static let cacheLock = NSLock()

    /// The table's patterns as one alternation, compiled once per language. Each rule keeps its
    /// one capturing group, so the group that matched names the rule.
    static func compiled(_ language: Language, _ table: Table) -> NSRegularExpression? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let hit = cache[language] { return hit }
        // One `^` for the whole alternation: ICU only skips to line starts when the anchor leads the
        // pattern, and an alternation of separately anchored branches cost ~5× the rules run alone.
        let joined = "^(?:" + table.rules.map { "(?:\(unanchored($0.pattern)))" }.joined(separator: "|") + ")"
        guard let regex = try? NSRegularExpression(pattern: joined, options: [.anchorsMatchLines]),
            regex.numberOfCaptureGroups == table.rules.count
        else { return nil }
        cache[language] = regex
        return regex
    }

    /// A rule's pattern without its leading `^` (inside a leading `(?i:` too); the alternation
    /// supplies the one anchor.
    private static func unanchored(_ pattern: String) -> String {
        if pattern.hasPrefix("^") { return String(pattern.dropFirst()) }
        if pattern.hasPrefix("(?i:^") { return "(?i:" + pattern.dropFirst(5) }
        return pattern
    }

    /// Whether every table compiles with one capturing group per rule — for the tests.
    static var everyTableCompiles: [Language: Bool] {
        Dictionary(uniqueKeysWithValues: tables.map { ($0.key, compiled($0.key, $0.value) != nil) })
    }
}

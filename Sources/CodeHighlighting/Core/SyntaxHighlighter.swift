//
//  SyntaxHighlighter.swift
//  CodeHighlighting
//
//  Dependency-light regex syntax highlighter with per-language rules and a
//  family-based fallback, covering every language CodeLanguage recognizes.
//
//  Created by David Sherlock on 7/9/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import CodeLanguage

/// Dependency-light regex highlighter: per-language rule tables for the common
/// languages, plus a `HighlightFamily` fallback so every language `CodeLanguage`
/// recognizes gets sensible coloring — no grammars or bundles required.
///
/// Use it as the fallback when ``TreeSitterHighlighter`` has no grammar for the
/// language (`TreeSitterHighlighter.supports(_:)` is false).
public final class SyntaxHighlighter: CodeHighlighter {
    /// A compiled pattern paired with the token role it paints, and the scopes it may match in (none:
    /// anywhere). See ``RuleScope``.
    private typealias Rule = (regex: NSRegularExpression, kind: TokenKind, scopes: [RuleScope])

    // Rules are grouped so precedence is correct regardless of authoring order:
    // code rules apply first, then strings and comments are resolved together in
    // one left-to-right scan where the earliest-starting match wins its whole
    // span — so a keyword inside a string/comment stays quiet, a comment marker
    // inside a string ("https://…") can't repaint the string, and a quote inside
    // a comment can't start a string.
    private let codeRules: [Rule]
    private let stringRules: [Rule]
    private let commentRules: [Rule]
    private let colors: TokenColorProviding

    /// Builds the rule tables for `language`, painting with `colors`.
    /// Never fails: an unknown language falls back to its family's rules
    /// (worst case, plain text gets no rules and stays uncolored).
    public convenience init(language: Language, colors: TokenColorProviding) {
        self.init(defs: RuleTables.table(for: language), regexOptions: .anchorsMatchLines, colors: colors)
    }

    /// Shared designated initializer: compiles a `(pattern, kind)` table into
    /// the three rule groups. Backs both the built-in-language init above and
    /// `init(custom:colors:)` (custom language definitions). A pattern that
    /// fails to compile is skipped — never fatal.
    init(defs: [(String, TokenKind)], regexOptions: NSRegularExpression.Options, colors: TokenColorProviding) {
        self.colors = colors
        var code: [Rule] = []
        var strings: [Rule] = []
        var comments: [Rule] = []
        for (pattern, kind) in defs {
            let (scopes, body) = RuleScope.split(pattern)
            guard let regex = try? NSRegularExpression(pattern: body, options: regexOptions) else { continue }
            switch kind {
            case .comment: comments.append((regex, kind, scopes))
            case .string: strings.append((regex, kind, scopes))
            default: code.append((regex, kind, scopes))
            }
        }
        codeRules = code
        stringRules = strings
        commentRules = comments
    }

    /// Recolors the lines that intersect `editedRange` (expanded to whole lines).
    /// Only the `.foregroundColor` attribute is touched — never `.font`, which
    /// would invalidate layout on every keystroke.
    @MainActor
    public func highlight(_ storage: NSTextStorage, in editedRange: NSRange) {
        let string = storage.string as NSString
        guard string.length > 0 else { return }

        // Clamp like TreeSitterHighlighter.highlight does: the two tiers are
        // interchangeable, so a stale range safe against one must not crash the other.
        let start = string.lineRange(for: NSRange(location: min(editedRange.location, string.length), length: 0)).location
        let end: Int = {
            let e = NSMaxRange(editedRange)
            let clamped = min(e, string.length)
            return NSMaxRange(string.lineRange(for: NSRange(location: max(clamped - 1, 0), length: 0)))
        }()
        let range = NSRange(location: start, length: end - start)
        guard range.length > 0 else { return }

        // Only reset the color — NOT the font. Changing .font invalidates the
        // layout manager's glyphs on every keystroke/scroll, which races with the
        // gutter's glyph queries and can crash. The font is already set once when
        // the storage is built (and rebuilt on font-size change), so leave it alone.
        storage.addAttribute(.foregroundColor, value: colors.foreground, range: range)

        let text = Self.fixedText(of: storage, painting: range.length)
        var canvas = paintedCanvas(text, in: range)

        // Same leftover-marker tint as the tree-sitter tier: a marker whose run
        // was just painted comment-colored takes the keyword color. Read off the
        // canvas, not the storage: a storage read mid-edit fixes its attributes first.
        CommentKeywords.regex.enumerateMatches(in: text, options: [], range: range) { m, _, _ in
            guard let r = m?.range, r.length > 0, canvas.kind(at: r.location) == .comment else { return }
            canvas.paint(r, .keyword)
        }
        canvas.flush(into: storage, colors: colors)
    }

    /// Runs the rule tables over exactly `range` — no line expansion and, unlike
    /// ``highlight(_:in:)``, no reset to the default foreground first.
    ///
    /// The seam ``EmbeddedMarkupHighlighter`` paints its markup spans through: an
    /// SFC's markup is a set of disjoint sub-ranges rather than one contiguous
    /// block, so the caller owns both the reset and the clipping. Matching is
    /// still evaluated against the whole document (a rule may look behind
    /// `range.location`), only the *matches* are confined to `range`.
    func paint(_ storage: NSTextStorage, in range: NSRange) {
        guard range.length > 0 else { return }
        paintedCanvas(Self.fixedText(of: storage, painting: range.length), in: range).flush(into: storage, colors: colors)
    }

    /// ``paint(_:in:)`` over several ranges, reading the storage's text once: a Quarto document's chunks
    /// and the prose between them are hundreds of ranges, and each read copies the whole document.
    func paint(_ storage: NSTextStorage, in ranges: [NSRange]) {
        let text = Self.fixedText(of: storage, painting: ranges.reduce(0) { $0 + $1.length })
        for range in ranges where range.length > 0 { paintedCanvas(text, in: range).flush(into: storage, colors: colors) }
    }

    /// The text the rules scan to paint `length` characters: for a large paint an immutable copy of the
    /// storage's, as a scan of the storage's own mutable string runs about twice as slow; for the few lines
    /// an edit repaints, the storage's own, so a keystroke never copies the whole document. A
    /// ``PaintBuffer``'s text is immutable already.
    private static func fixedText(of storage: NSTextStorage, painting length: Int) -> String {
        if let buffer = storage as? PaintBuffer { return buffer.string }
        return length < 16_384 ? storage.string : NSString(string: storage.string) as String
    }

    /// Every rule's paint over `range` of `text`, not yet in any storage.
    private func paintedCanvas(_ text: String, in range: NSRange) -> Canvas {
        var regions = Regions(text: text, range: range)
        var canvas = Canvas(range: range)
        apply(codeRules, to: &canvas, in: text, range: range, regions: &regions)
        applyStringsAndComments(to: &canvas, in: text, range: range, regions: &regions)
        return canvas
    }

    /// The role each character of one paint ends with. Rules write here in table order — a later one
    /// repaints an earlier one, as before — and the result reaches the storage once, run by run, left
    /// to right. Painting the storage rule by rule instead inserted every token's run into the middle of
    /// its attribute array, which grows with the square of the tokens on a large file.
    private struct Canvas {
        let range: NSRange
        /// Per character: 0 untouched, else 1 + the index of its kind in `kinds`.
        private var marks: [UInt8]
        private var kinds: [TokenKind] = []

        init(range: NSRange) {
            self.range = range
            marks = [UInt8](repeating: 0, count: range.length)
        }

        /// Paints `r` (clipped to the paint's range) as `kind`.
        mutating func paint(_ r: NSRange, _ kind: TokenKind) {
            let clipped = NSIntersectionRange(r, range)
            guard clipped.length > 0 else { return }
            let mark: UInt8
            if let i = kinds.firstIndex(of: kind) {
                mark = UInt8(i + 1)
            } else {
                kinds.append(kind)
                mark = UInt8(kinds.count)
            }
            let start = clipped.location - range.location
            for i in start..<(start + clipped.length) { marks[i] = mark }
        }

        /// The kind painted at `location`, or nil when nothing painted it.
        func kind(at location: Int) -> TokenKind? {
            let i = location - range.location
            guard i >= 0, i < marks.count, marks[i] != 0 else { return nil }
            return kinds[Int(marks[i]) - 1]
        }

        /// Writes every painted run to `storage`, ascending; untouched characters keep their colour.
        func flush(into storage: NSTextStorage, colors: TokenColorProviding) {
            let palette = kinds.map { colors.color(for: $0) }
            var i = 0
            while i < marks.count {
                let mark = marks[i]
                var j = i + 1
                while j < marks.count, marks[j] == mark { j += 1 }
                if mark != 0 {
                    storage.addAttribute(
                        .foregroundColor, value: palette[Int(mark) - 1], range: NSRange(location: range.location + i, length: j - i))
                }
                i = j
            }
        }
    }

    /// Paints every match of `rules` within `range`, in table order; a scoped rule's only where it
    /// starts inside one of its regions.
    private func apply(_ rules: [Rule], to canvas: inout Canvas, in text: String, range: NSRange, regions: inout Regions) {
        for rule in rules {
            let allowed = rule.scopes.isEmpty ? nil : regions.union(of: rule.scopes)
            rule.regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
                guard let r = match?.range else { return }
                if let allowed, !RuleScope.contains(r.location, in: allowed) { return }
                canvas.paint(r, rule.kind)
            }
        }
    }

    /// One paint's scope regions, each scope's found once and on first use.
    private struct Regions {
        let text: String
        let range: NSRange
        private var found: [String: [NSRange]] = [:]

        init(text: String, range: NSRange) {
            self.text = text
            self.range = range
        }

        /// The union of `scopes`' regions around the painted range.
        mutating func union(of scopes: [RuleScope]) -> [NSRange] {
            RuleScope.union(
                scopes.map { scope in
                    let key = scope.region.pattern
                    if let known = found[key] { return known }
                    let regions = scope.regions(in: text, around: range)
                    found[key] = regions
                    return regions
                })
        }
    }

    /// Strings and comments must be resolved together: applying one group after
    /// the other let a comment marker inside a string literal (`"https://…"`,
    /// `'a--b'`) repaint the rest of the line as a comment, and vice versa.
    /// This walks the range once, left to right, always accepting the
    /// earliest-starting match (longest on a tie) and re-searching any rule
    /// whose next match overlapped an already-accepted span.
    private func applyStringsAndComments(to canvas: inout Canvas, in text: String, range: NSRange, regions: inout Regions) {
        let rules = stringRules + commentRules
        guard !rules.isEmpty else { return }
        var allowed: [[NSRange]?] = []
        for rule in rules { allowed.append(rule.scopes.isEmpty ? nil : regions.union(of: rule.scopes)) }
        let end = NSMaxRange(range)
        var pos = range.location
        // Cached next match per rule: nil = needs (re)searching from `pos`;
        // location == NSNotFound = the rule has no further matches.
        var next = [NSRange?](repeating: nil, count: rules.count)
        while pos < end {
            var best: (range: NSRange, kind: TokenKind)?
            for i in rules.indices {
                if let cached = next[i], cached.location == NSNotFound { continue }
                if next[i] == nil || next[i]!.location < pos {
                    // A scoped rule's match that starts outside its regions is skipped: search on from
                    // the character after it. A search that would start outside every region starts at
                    // the next region instead: the gap holds no match the rule may keep, and scanning it
                    // with a pattern that opens with a look back costs a pass over the text per rule. The
                    // jump finds what the scan through the gap would have: a word boundary at the region
                    // reads the character before it (transparent bounds), and `^` and `\A` match there only
                    // where the text has them (no anchoring bounds).
                    var from = pos
                    var found: NSRange?
                    var options: NSRegularExpression.MatchingOptions = []
                    while from < end {
                        if let regions = allowed[i] {
                            guard let start = RuleScope.firstStart(atOrAfter: from, in: regions), start < end else { break }
                            if start > from {
                                from = start
                                options = [.withTransparentBounds, .withoutAnchoringBounds]
                            }
                        }
                        let search = NSRange(location: from, length: end - from)
                        found = rules[i].regex.firstMatch(in: text, options: options, range: search)?.range
                        options = []
                        guard let f = found, let regions = allowed[i], !RuleScope.contains(f.location, in: regions) else { break }
                        from = f.location + 1
                        found = nil
                    }
                    next[i] = (found?.length ?? 0) > 0 ? found : NSRange(location: NSNotFound, length: 0)
                }
                guard let m = next[i], m.location != NSNotFound else { continue }
                // Earliest start wins; at the same start a COMMENT beats a string (Vim script's `"`
                // opens both, and a line that starts with it is a comment), else the longer match.
                let tie = best.map { m.location == $0.range.location } ?? false
                let commentBeatsString = tie && rules[i].kind == .comment && best!.kind == .string
                let stringLosesToComment = tie && rules[i].kind == .string && best!.kind == .comment
                if best == nil || m.location < best!.range.location || commentBeatsString
                    || (tie && !stringLosesToComment && m.length > best!.range.length)
                {
                    best = (m, rules[i].kind)
                }
            }
            guard let win = best else { break }
            canvas.paint(win.range, win.kind)
            pos = NSMaxRange(win.range)
        }
    }
}

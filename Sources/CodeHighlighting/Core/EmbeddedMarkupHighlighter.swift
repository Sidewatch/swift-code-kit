//
//  EmbeddedMarkupHighlighter.swift
//  CodeHighlighting
//
//  Single-file-component highlighting (Astro / Vue / Svelte) and executable
//  Markdown (Quarto / R Markdown): splits the document into markup and
//  embedded-language regions, then paints each region with the best highlighter
//  available for *that* language.
//
//  Created by David Sherlock on 7/30/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import CodeLanguage
import FoundationExtensions
import struct SwiftTreeSitter.Node
import class SwiftTreeSitter.Parser

/// Highlighter for single-file components (`.astro`, `.vue`, `.svelte`), whose bodies stack
/// several languages: Astro frontmatter → TypeScript, `<script>` → TS/JS/JSON and `<style>` →
/// CSS/SCSS/Sass/Less (per `lang=`/`type=`), the rest → the host's markup rules. One flat rule
/// table cannot do this: it leaves `<style>` uncoloured and paints CSS's `in` as a JS keyword.
/// Quarto and R Markdown chunks (```` ```{r} ````, ```` ```{python echo=FALSE} ````) are regions the
/// same way: each body in its chunk's language, the fence lines as keywords.
/// Regions with a bundled grammar are parsed in place like injections; the rest use their own
/// regex table. Paints only `.foregroundColor`, on the main thread.
public final class EmbeddedMarkupHighlighter: CodeHighlighter {

    /// An embedded span of a non-markup language: the body range (tag/fence
    /// delimiters excluded) and the language to paint it with.
    public struct Region {
        /// The body's range, delimiters excluded.
        public let range: NSRange
        /// The language the body is painted as.
        public let language: Language
    }

    /// The host SFC language (drives frontmatter handling and `<script>`'s
    /// default dialect).
    private let language: Language

    /// Rules for the markup between the embedded regions — the host language's
    /// existing table.
    private let markup: SyntaxHighlighter

    private let colors: TokenColorProviding

    /// Regex tables for embedded languages with no bundled grammar, built on
    /// first use. Main-thread only, like every other paint path here.
    private var fallbacks: [Language: SyntaxHighlighter] = [:]

    /// Whether `language` is a single-file-component format this handles.
    /// Hosts should try this tier between ``TreeSitterHighlighter`` and the
    /// plain ``SyntaxHighlighter``.
    public static func supports(_ language: Language) -> Bool {
        switch language {
        case .astro, .vue, .svelte, .quarto, .rmarkdown: return true
        default: return false
        }
    }

    /// Creates a highlighter for an SFC `language`, or nil for anything
    /// ``supports(_:)`` rejects — so a host can chain it with `??`.
    public init?(language: Language, colors: TokenColorProviding) {
        guard Self.supports(language) else { return nil }
        self.language = language
        self.colors = colors
        self.markup =
            Self.isExecutableMarkdown(language)
            ? SyntaxHighlighter(defs: RuleTables.quartoMarkup, regexOptions: .anchorsMatchLines, colors: colors)
            : SyntaxHighlighter(language: language, colors: colors)
    }

    // MARK: - Painting

    /// Repaints the whole lines around `editedRange`: markup rules first, then each embedded
    /// region over its own slice.
    @MainActor
    public func highlight(_ storage: NSTextStorage, in editedRange: NSRange) {
        // An immutable copy, once: the storage's own string is mutable, so every parse would copy it again
        // and every character read would be a message to it.
        let ns = NSString(string: storage.string)
        guard ns.length > 0 else { return }
        let full = NSRange(location: 0, length: ns.length)

        // Expand to whole lines and clamp exactly like the other two tiers: the
        // three are interchangeable, so a stale range safe against one must not
        // crash the others.
        let lo = ns.lineRange(for: NSRange(location: min(editedRange.location, ns.length), length: 0))
        let hi = ns.lineRange(for: NSRange(location: min(NSMaxRange(editedRange), ns.length), length: 0))
        let clip = NSIntersectionRange(lo.union(hi), full)
        guard clip.length > 0 else { return }

        // One reset for the whole clip, then every region paints over its own
        // slice — markup and embedded spans are disjoint, so order between them
        // doesn't matter and neither can erase the other.
        storage.addAttribute(.foregroundColor, value: colors.foreground, range: clip)

        let chunks = Self.isExecutableMarkdown(language) ? Self.chunks(in: ns) : []
        let regions =
            Self.isExecutableMarkdown(language) ? Self.markdownRegions(in: ns, chunks: chunks) : Self.regions(in: ns, language: language)
        var painted: [NSRange] = []
        if Self.isExecutableMarkdown(language) {
            // Hundreds of chunks: one parse per language over all of its chunks, and one pass of each
            // table over all of its ranges. Painting them one by one re-read the whole document each time.
            painted = paintGrouped(regions, storage: storage, ns: ns, clip: clip)
            markup.paint(storage, in: Self.complement(of: painted, within: clip))
        } else {
            for region in regions {
                let visible = NSIntersectionRange(region.range, clip)
                guard visible.length > 0 else { continue }
                painted.append(region.range)
                paint(region.language, storage: storage, ns: ns, body: region.range, clip: visible)
            }
            // The markup is whatever the embedded regions left over.
            for gap in Self.complement(of: painted, within: clip) {
                markup.paint(storage, in: gap)
            }
            paintExpressions(regions: regions, storage: storage, ns: ns, clip: clip)
        }

        if !chunks.isEmpty { paintChunkEdges(chunks, storage: storage, ns: ns, clip: clip) }
        if language == .astro || Self.isExecutableMarkdown(language) { paintFrontmatterFences(storage: storage, ns: ns, clip: clip) }
    }

    /// The code in the markup — Svelte's and Astro's `{ … }`, Svelte's block tags, Vue's `{{ … }}` and
    /// directive values — painted by the TypeScript grammar (TSX for Astro, whose expressions hold JSX), each
    /// expression a statement of its own in one combined parse; the braces around one are punctuation.
    @MainActor
    private func paintExpressions(regions: [Region], storage: NSTextStorage, ns: NSString, clip: NSRange) {
        let gaps = Self.complement(of: regions.map(\.range), within: NSRange(location: 0, length: ns.length))
        let expressions: [TemplateExpression]
        switch language {
        case .svelte: expressions = TemplateExpressionScanner.svelte(in: ns, gaps: gaps)
        case .astro: expressions = TemplateExpressionScanner.astro(in: ns, gaps: gaps)
        case .vue: expressions = TemplateExpressionScanner.vue(in: ns, gaps: gaps)
        default: return
        }
        guard let grammar = TreeSitterHighlighter.grammar(for: language == .astro ? .tsx : .typescript) else { return }
        // Every visible expression in one parse: each is its own statement in a combined source, so one tree and one
        // query pass serve them all, and its hits map back by the offset it was written at.
        var pieces: [(expression: TemplateExpression, slice: NSRange, span: NSRange)] = []
        var code = ""
        var length = 0
        for expression in expressions {
            for brace in expression.braces {
                let shown = NSIntersectionRange(brace, clip)
                if shown.length > 0 { storage.addAttribute(.foregroundColor, value: colors.foreground, range: shown) }
            }
            let slice = NSIntersectionRange(expression.body, clip)
            guard slice.length > 0 else { continue }
            let piece = expression.prefix + ns.substring(with: expression.body) + expression.suffix + "\n;\n"
            let pieceLength = (piece as NSString).length
            pieces.append((expression, slice, NSRange(location: length, length: pieceLength)))
            code += piece
            length += pieceLength
        }
        guard !pieces.isEmpty else { return }
        let parser = Parser()
        try? parser.setLanguage(grammar.language)
        guard let tree = parser.parse(code), let root = tree.rootNode else { return }
        let errors = Self.errorRanges(in: root)
        let spans = pieces.map(\.span)
        var own = [[TreeSitterHighlighter.Hit]](repeating: [], count: pieces.count)
        var base = 0
        let source = code as NSString
        for hit in TreeSitterHighlighter.collectHits(
            grammar.highlights, tree: tree, source: source, offset: 0, clip: NSRange(location: 0, length: source.length), nextBase: &base)
        {
            let low = Self.pieceIndex(holding: hit.range.location, in: spans)
            let shift =
                pieces[low].expression.body.location - pieces[low].span.location - (pieces[low].expression.prefix as NSString).length
            own[low].append((NSRange(location: hit.range.location + shift, length: hit.range.length), hit.pattern, hit.color))
        }
        // An error that crosses from one piece into another may have misread both: those pieces parse again alone.
        // An error inside one piece is that piece's own, and parsing it alone would find the same.
        var spoiled = Set<Int>()
        for error in errors {
            let first = Self.pieceIndex(holding: error.location, in: spans)
            let last = Self.pieceIndex(holding: max(error.location, NSMaxRange(error) - 1), in: spans)
            if last > first { spoiled.formUnion(first...last) }
        }
        var runs: [(range: NSRange, color: NSColor)] = []
        for (index, piece) in pieces.enumerated() {
            let hits = spoiled.contains(index) ? isolatedHits(piece.expression, grammar: grammar, parser: parser, ns: ns) : own[index]
            runs += resolve(hits, over: piece.slice)
        }
        rewrite(clip, overlaying: runs, into: storage)
    }

    /// The colour runs of `slice` as `hits` resolve it: the highest pattern wins, and a hit leaves the code holes it
    /// strictly contains (a template literal's `${…}`) to the hits inside them.
    private func resolve(_ hits: [TreeSitterHighlighter.Hit], over slice: NSRange) -> [(range: NSRange, color: NSColor)] {
        var palette: [NSColor] = [colors.foreground]
        var desired = [Int](repeating: 0, count: slice.length)
        let holes = hits.filter { $0.color === TreeSitterHighlighter.codeHole }.map(\.range)
        for hit in hits.sorted(by: { $0.pattern < $1.pattern }) where hit.color !== TreeSitterHighlighter.codeHole {
            let r = NSIntersectionRange(hit.range, slice)
            guard r.length > 0 else { continue }
            let inside = holes.filter { NSEqualRanges(NSIntersectionRange($0, hit.range), $0) && !NSEqualRanges($0, hit.range) }
            var colour = palette.firstIndex { $0 === hit.color } ?? palette.count
            if colour == palette.count { palette.append(hit.color) }
            for i in r.location..<NSMaxRange(r) where !inside.contains(where: { NSLocationInRange(i, $0) }) {
                desired[i - slice.location] = colour
            }
        }
        var runs: [(range: NSRange, color: NSColor)] = []
        var start = 0
        while start < desired.count {
            var end = start + 1
            while end < desired.count, desired[end] == desired[start] { end += 1 }
            runs.append((NSRange(location: slice.location + start, length: end - start), palette[desired[start]]))
            start = end
        }
        return runs
    }

    /// Writes `runs` (ascending, disjoint) over `clip`, skipping each part that already wears its colour: a write in
    /// the middle of a large document shifts the storage's attribute runs after it, so the fewer the better. The
    /// storage's colours are read in one pass beside the runs.
    @MainActor
    private func rewrite(_ clip: NSRange, overlaying runs: [(range: NSRange, color: NSColor)], into storage: NSTextStorage) {
        guard let first = runs.first, let last = runs.last else { return }
        let span = NSIntersectionRange(NSRange(location: first.range.location, length: NSMaxRange(last.range) - first.range.location), clip)
        guard span.length > 0 else { return }
        var stale: [(range: NSRange, color: NSColor)] = []
        var next = 0
        storage.enumerateAttribute(.foregroundColor, in: span, options: []) { value, range, _ in
            let existing = value as? NSColor
            while next < runs.count, NSMaxRange(runs[next].range) <= range.location { next += 1 }
            var index = next
            while index < runs.count, runs[index].range.location < NSMaxRange(range) {
                let run = runs[index]
                let part = NSIntersectionRange(run.range, range)
                if part.length > 0, !(existing === run.color), !(existing?.isEqual(run.color) ?? false) {
                    if let previous = stale.last, NSMaxRange(previous.range) == part.location, previous.color === run.color {
                        stale[stale.count - 1].range.length += part.length
                    } else {
                        stale.append((part, run.color))
                    }
                }
                index += 1
            }
        }
        for run in stale { storage.addAttribute(.foregroundColor, value: run.color, range: run.range) }
    }

    /// The index of the last of `spans` (ascending) that starts at or before `location`.
    private static func pieceIndex(holding location: Int, in spans: [NSRange]) -> Int {
        var low = 0
        var high = spans.count - 1
        while low < high {
            let mid = (low + high + 1) / 2
            if spans[mid].location <= location { low = mid } else { high = mid - 1 }
        }
        return low
    }

    /// `expression` parsed on its own, its hits in document offsets.
    @MainActor
    private func isolatedHits(
        _ expression: TemplateExpression, grammar: TreeSitterHighlighter.Grammar, parser: Parser, ns: NSString
    ) -> [TreeSitterHighlighter.Hit] {
        let code = (expression.prefix + ns.substring(with: expression.body) + expression.suffix) as NSString
        guard let tree = parser.parse(code as String) else { return [] }
        var base = 0
        return TreeSitterHighlighter.collectHits(
            grammar.highlights, tree: tree, source: code, offset: expression.body.location - (expression.prefix as NSString).length,
            clip: expression.body, nextBase: &base)
    }

    /// The ranges of the ERROR and MISSING nodes under `node`, descending only where an error lives.
    private static func errorRanges(in node: Node) -> [NSRange] {
        guard node.hasError else { return [] }
        if node.nodeType == "ERROR" || node.isMissing { return [node.range] }
        return (0..<node.childCount).flatMap { index in node.child(at: index).map { errorRanges(in: $0) } ?? [] }
    }

    /// The `---` lines around the frontmatter are comments, as VS Code scopes Astro's and Markdown's.
    @MainActor
    private func paintFrontmatterFences(storage: NSTextStorage, ns: NSString, clip: NSRange) {
        guard let fence = Self.frontmatter(in: ns) else { return }
        let lines = [ns.lineRange(for: NSRange(location: 0, length: 0)), ns.lineRange(for: NSRange(location: fence.end - 1, length: 0))]
        for line in lines {
            let visible = NSIntersectionRange(line, clip)
            if visible.length > 0 { storage.addAttribute(.foregroundColor, value: colors.color(for: .comment), range: visible) }
        }
    }

    /// The parts of a Quarto / R Markdown block that are not code: a chunk's fence lines are keywords
    /// and its `#| key:` option names attributes; a block shown rather than run (```` ```python ````)
    /// keeps the Markdown look of fences as text, and a block in no known language is text throughout.
    @MainActor
    private func paintChunkEdges(_ chunks: [Chunk], storage: NSTextStorage, ns: NSString, clip: NSRange) {
        func paint(_ range: NSRange, _ kind: TokenKind) {
            let visible = NSIntersectionRange(range, clip)
            if visible.length > 0 { storage.addAttribute(.foregroundColor, value: colors.color(for: kind), range: visible) }
        }
        for chunk in chunks {
            for fence in chunk.fences { paint(fence, chunk.braced ? .keyword : .string) }
            if chunk.language == nil, let body = chunk.body { paint(body, .string) }
            for line in chunk.options {
                let text = ns.substring(with: line) as NSString
                guard
                    let key = Self.optionKey?.firstMatch(in: text as String, options: [], range: NSRange(location: 0, length: text.length))
                else { continue }
                paint(NSRange(location: line.location + key.range.location, length: key.range.length), .attribute)
            }
        }
    }

    /// Paints one embedded region. `body` is the region's full extent (the
    /// parser needs all of it for a valid parse even when only part is on
    /// screen); `clip` is the visible slice actually recolored.
    @MainActor
    private func paint(_ lang: Language, storage: NSTextStorage, ns: NSString, body: NSRange, clip: NSRange) {
        if let grammar = TreeSitterHighlighter.grammar(for: lang),
            let tree = TreeSitterHighlighter.combinedParse(grammar, ns: ns, ranges: [body])
        {
            // `combinedParse` restricts the parser to `body` via includedRanges,
            // so capture ranges come back in document coordinates already —
            // offset stays 0, exactly as in the injection pass.
            var base = 0
            var hits = TreeSitterHighlighter.collectHits(
                grammar.highlights, tree: tree, source: ns,
                offset: 0, clip: clip, nextBase: &base)
            hits += TreeSitterHighlighter.collectInjectionHits(
                grammar, tree: tree, source: ns,
                offset: 0, clip: clip, depth: 0,
                nextBase: &base)
            TreeSitterHighlighter.applyResolved(
                hits: hits, clip: clip,
                defaultColor: colors.foreground, into: storage)
            return
        }
        fallback(for: lang).paint(storage, in: clip)
    }

    /// Paints the regions that reach into `clip`, all of one language together: a single parse over every
    /// body of a grammar language (the chunks of a Quarto document share one session, so one parse is
    /// also the truer reading), a single pass of the table over every body of the rest. Returns the
    /// regions' full ranges, for the markup to paint around.
    @MainActor
    private func paintGrouped(_ regions: [Region], storage: NSTextStorage, ns: NSString, clip: NSRange) -> [NSRange] {
        var order: [Language] = []
        var bodies: [Language: [NSRange]] = [:]
        for region in regions where NSIntersectionRange(region.range, clip).length > 0 {
            if bodies[region.language] == nil { order.append(region.language) }
            bodies[region.language, default: []].append(region.range)
        }
        for lang in order {
            let ranges = bodies[lang] ?? []
            let visible = ranges.map { NSIntersectionRange($0, clip) }
            if let grammar = TreeSitterHighlighter.grammar(for: lang),
                let tree = TreeSitterHighlighter.combinedParse(grammar, ns: ns, ranges: ranges)
            {
                var base = 0
                let hits =
                    TreeSitterHighlighter.collectHits(grammar.highlights, tree: tree, source: ns, offset: 0, clip: clip, nextBase: &base)
                    + TreeSitterHighlighter.collectInjectionHits(
                        grammar, tree: tree, source: ns, offset: 0, clip: clip, depth: 0, nextBase: &base)
                // Hits sorted by start, so each body takes its own slice instead of filtering them all.
                let sorted = hits.sorted { $0.range.location < $1.range.location }
                var first = 0
                for slice in visible {
                    while first < sorted.count, NSMaxRange(sorted[first].range) <= slice.location { first += 1 }
                    var own: [TreeSitterHighlighter.Hit] = []
                    var i = first
                    while i < sorted.count, sorted[i].range.location < NSMaxRange(slice) {
                        if NSIntersectionRange(sorted[i].range, slice).length > 0 { own.append(sorted[i]) }
                        i += 1
                    }
                    TreeSitterHighlighter.applyResolved(hits: own, clip: slice, defaultColor: colors.foreground, into: storage)
                }
            } else {
                fallback(for: lang).paint(storage, in: visible)
            }
        }
        return order.flatMap { bodies[$0] ?? [] }
    }

    /// The regex table for an embedded language with no bundled grammar.
    private func fallback(for lang: Language) -> SyntaxHighlighter {
        if let h = fallbacks[lang] { return h }
        let h = SyntaxHighlighter(language: lang, colors: colors)
        fallbacks[lang] = h
        return h
    }

    // MARK: - Region scanning

    /// Every embedded-language region in `ns`, ascending and non-overlapping.
    /// Public so hosts can report the split (see `--dump-captures`).
    public static func regions(in ns: NSString, language: Language) -> [Region] {
        var out: [Region] = []
        var scanFrom = 0

        // Astro's frontmatter is TypeScript. Scan tags only *after* it, so a
        // `<style>` mentioned in a frontmatter string can't open a fake region.
        if language == .astro, let fence = frontmatter(in: ns) {
            if fence.body.length > 0 { out.append(Region(range: fence.body, language: .typescript)) }
            scanFrom = fence.end
        }

        if isExecutableMarkdown(language) { return markdownRegions(in: ns, chunks: chunks(in: ns)) }

        out += tagRegions(in: ns, from: scanFrom, host: language)
        if language == .vue {
            out = (out + customBlockRegions(in: ns)).sorted { $0.range.location < $1.range.location }
        }
        return out
    }

    // MARK: - Quarto / R Markdown chunks

    /// Whether `language` is Markdown whose fences carry code to run (Quarto, R Markdown).
    static func isExecutableMarkdown(_ language: Language) -> Bool { language == .quarto || language == .rmarkdown }

    /// One fenced block: a chunk the document runs (```` ```{r label, echo=FALSE} ````), a block it
    /// only shows (```` ```python ````), or a block in no known language.
    struct Chunk {
        /// The code between the fence lines and after any option lines; nil when empty.
        let body: NSRange?
        /// The language the fence names; nil when it names none Sidewatch knows.
        let language: Language?
        /// The opening fence line and, when there is one, the closing fence line (line breaks excluded).
        let fences: [NSRange]
        /// The `#| key: value` option lines at the top of a chunk (line breaks excluded).
        let options: [NSRange]
        /// Whether the info string is braced, which makes the block a chunk.
        let braced: Bool
    }

    /// The YAML front matter, then every chunk's code, as regions to paint.
    static func markdownRegions(in ns: NSString, chunks: [Chunk]) -> [Region] {
        var out: [Region] = []
        if let fence = frontmatter(in: ns), fence.body.length > 0 { out.append(Region(range: fence.body, language: .yaml)) }
        for chunk in chunks {
            if let language = chunk.language, let body = chunk.body { out.append(Region(range: body, language: language)) }
        }
        return out
    }

    /// An opening fence: up to three spaces, three or more backticks or tildes, then the info string.
    /// Group 1 is the fence, 2 a braced engine name (`{r …}`, `{=html}`, Pandoc's `{.python …}`), 3 a bare
    /// language name.
    private static let fenceOpen = try? NSRegularExpression(
        pattern: #"^[ \t]{0,3}(`{3,}|~{3,})[ \t]*(?:\{[ \t]*[=.]?([A-Za-z][\w.+-]*)[^}\n]*\}|([A-Za-z][\w.+-]*))?[^\n]*$"#,
        options: [])

    /// A chunk option line: `#|`, `//|`, `--|` or Mermaid's `%%|`, then the option's name and colon.
    private static let optionLine = try? NSRegularExpression(pattern: #"^[ \t]*(?:#|//|--|%%)\|"#, options: [])
    /// The `#| name:` part of an option line, painted as an attribute.
    fileprivate static let optionKey = try? NSRegularExpression(pattern: #"^[ \t]*(?:#|//|--|%%)\|[ \t]*[\w.-]*:?"#, options: [])

    /// Every fenced block in `ns`, in order. One forward pass over the lines: a block runs from its
    /// opening fence to the first line of only its fence character, at least as many, so a fence inside
    /// a longer fence's block is text.
    static func chunks(in ns: NSString) -> [Chunk] {
        guard let fenceOpen else { return [] }
        var out: [Chunk] = []
        var loc = 0
        while loc < ns.length {
            let line = ns.lineRange(for: NSRange(location: loc, length: 0))
            guard line.length > 0 else { break }
            loc = NSMaxRange(line)
            let content = contentRange(of: line, in: ns)
            let text = ns.substring(with: content)
            guard text.contains("```") || text.contains("~~~"),
                let match = fenceOpen.firstMatch(in: text, options: [], range: NSRange(location: 0, length: content.length))
            else { continue }
            let tn = text as NSString
            let fence = tn.substring(with: match.range(at: 1))
            let braced = match.range(at: 2).location != NSNotFound
            let nameGroup = braced ? 2 : 3
            let name = match.range(at: nameGroup).location == NSNotFound ? "" : tn.substring(with: match.range(at: nameGroup))
            let close = closingFence(after: loc, fence: fence, in: ns)
            let bodyEnd = close?.line.location ?? ns.length
            var bodyStart = loc
            var options: [NSRange] = []
            if braced, let optionLine {
                while bodyStart < bodyEnd {
                    let next = ns.lineRange(for: NSRange(location: bodyStart, length: 0))
                    let nextText = ns.substring(with: next)
                    guard
                        optionLine.firstMatch(in: nextText, options: [], range: NSRange(location: 0, length: (nextText as NSString).length))
                            != nil
                    else { break }
                    options.append(contentRange(of: next, in: ns))
                    bodyStart = NSMaxRange(next)
                }
            }
            loc = close?.next ?? ns.length
            var fences = [content]
            if let close { fences.append(contentRange(of: close.line, in: ns)) }
            let body = bodyEnd > bodyStart ? NSRange(location: bodyStart, length: bodyEnd - bodyStart) : nil
            out.append(Chunk(body: body, language: chunkLanguage(name), fences: fences, options: options, braced: braced))
        }
        return out
    }

    /// `line` without its line break.
    private static func contentRange(of line: NSRange, in ns: NSString) -> NSRange {
        var end = NSMaxRange(line)
        while end > line.location, ns.character(at: end - 1) == 0x0A || ns.character(at: end - 1) == 0x0D { end -= 1 }
        return NSRange(location: line.location, length: end - line.location)
    }

    /// The line that closes a block opened by `fence` (the same character, at least as many, at most
    /// three spaces before and nothing but blanks after), searching from `start`; its range and the
    /// offset after it.
    private static func closingFence(after start: Int, fence: String, in ns: NSString) -> (line: NSRange, next: Int)? {
        guard let char = fence.first else { return nil }
        var loc = start
        while loc < ns.length {
            let line = ns.lineRange(for: NSRange(location: loc, length: 0))
            guard line.length > 0 else { break }
            let raw = ns.substring(with: line)
            let indent = raw.prefix { $0 == " " }.count
            let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if indent <= 3, text.count >= fence.count, text.allSatisfy({ $0 == char }) { return (line, NSMaxRange(line)) }
            loc = NSMaxRange(line)
        }
        return nil
    }

    /// The language a fence names: knitr's and Quarto's engine names, then any language Sidewatch
    /// knows by that name. Nil for none, for Markdown itself, and for engines that hold prose
    /// (`{asis}`, bookdown's `{theorem}`).
    static func chunkLanguage(_ name: String) -> Language? {
        switch name.lowercased() {
        case "": return nil
        case "r", "rscript": return .r
        case "python", "py", "python3": return .python
        case "julia", "jl": return .julia
        case "bash", "sh", "shell", "zsh": return .bash
        case "ojs", "js", "javascript", "node": return .javascript
        case "ts": return .typescript
        case "rcpp", "c++": return .cpp
        case "dot", "graphviz": return .dot
        case "tikz", "tex": return .latex
        case "yml": return .yaml
        case "md", "markdown", "qmd", "rmd": return nil
        default:
            guard let language = Language(rawValue: name.lowercased()), language != .plainText,
                !isExecutableMarkdown(language), language != .markdown
            else { return nil }
            return language
        }
    }

    /// The leading `---` fence: the range between the fences, and the offset
    /// just past the closing fence line. Nil when the file doesn't open with one.
    private static func frontmatter(in ns: NSString) -> (body: NSRange, end: Int)? {
        guard ns.length >= 3 else { return nil }
        let opening = ns.lineRange(for: NSRange(location: 0, length: 0))
        guard ns.substring(with: opening).trimmed == "---" else { return nil }

        var loc = NSMaxRange(opening)
        while loc < ns.length {
            let line = ns.lineRange(for: NSRange(location: loc, length: 0))
            guard line.length > 0 else { break }  // no forward progress; bail rather than spin
            if ns.substring(with: line).trimmed == "---" {
                let start = NSMaxRange(opening)
                return (NSRange(location: start, length: line.location - start), NSMaxRange(line))
            }
            loc = NSMaxRange(line)
        }
        return nil  // unterminated fence: treat the whole file as markup
    }

    /// A Vue custom block that names its language: `<i18n lang="json">`, `<custom lang="yaml">`, at a line's start.
    /// Group 1 is the tag name, 2 the language.
    private static let customBlockTag = try? NSRegularExpression(
        pattern: "^<([a-z][\\w-]*)\\b[^>\\n]*\\blang\\s*=\\s*[\"']?([\\w+-]+)[^>\\n]*>", options: [.anchorsMatchLines])

    /// The bodies of Vue's custom blocks with a `lang` naming a language Sidewatch knows (`<i18n lang="json">`), each
    /// painted in that language. `<script>` and `<style>` are ``tagRegions(in:from:host:)``'s.
    private static func customBlockRegions(in ns: NSString) -> [Region] {
        guard let customBlockTag else { return [] }
        var out: [Region] = []
        customBlockTag.enumerateMatches(in: ns as String, options: [], range: NSRange(location: 0, length: ns.length)) { match, _, _ in
            guard let match else { return }
            let name = ns.substring(with: match.range(at: 1))
            guard name != "script", name != "style", name != "template" else { return }
            let lang = ns.substring(with: match.range(at: 2)).lowercased()
            guard let language = Language(rawValue: lang == "yml" ? "yaml" : lang), language != .plainText else { return }
            let bodyStart = NSMaxRange(match.range)
            let closing = ns.range(
                of: "</\(name)", options: .caseInsensitive, range: NSRange(location: bodyStart, length: ns.length - bodyStart))
            guard closing.location != NSNotFound, closing.location > bodyStart else { return }
            out.append(Region(range: NSRange(location: bodyStart, length: closing.location - bodyStart), language: language))
        }
        return out
    }

    /// Opening `<script …>` / `<style …>` tags. Attributes can't contain `>`,
    /// which is what bounds the match.
    private static let openTag = try? NSRegularExpression(
        pattern: "<(script|style)\\b([^>]*)>", options: [.caseInsensitive])

    /// Attribute pairs inside an opening tag, value quoted or bare.
    private static let attribute = try? NSRegularExpression(
        pattern: "([a-zA-Z_:][\\w:.-]*)\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)'|([^\\s>]+))", options: [])

    /// `<script>`/`<style>` bodies from `start` onward.
    private static func tagRegions(in ns: NSString, from start: Int, host: Language) -> [Region] {
        guard let openTag, start < ns.length else { return [] }
        let text = ns as String
        var out: [Region] = []
        var scanFrom = start

        while scanFrom < ns.length,
            let match = openTag.firstMatch(
                in: text, options: [],
                range: NSRange(location: scanFrom, length: ns.length - scanFrom))
        {
            let name = ns.substring(with: match.range(at: 1)).lowercased()
            let attrs = match.range(at: 2).location == NSNotFound ? "" : ns.substring(with: match.range(at: 2))
            let bodyStart = NSMaxRange(match.range)

            // `<script src="…" />` — self-closing, so there is no body and no
            // close tag to skip past.
            if attrs.hasSuffix("/") {
                scanFrom = bodyStart
                continue
            }

            // First close tag wins, exactly as an HTML tokenizer would treat it.
            let closing = ns.range(
                of: "</\(name)", options: .caseInsensitive,
                range: NSRange(location: bodyStart, length: ns.length - bodyStart))
            let bodyEnd = closing.location == NSNotFound ? ns.length : closing.location

            if bodyEnd > bodyStart, let lang = embeddedLanguage(tag: name, attributes: attrs, host: host) {
                out.append(Region(range: NSRange(location: bodyStart, length: bodyEnd - bodyStart), language: lang))
            }
            scanFrom = closing.location == NSNotFound ? ns.length : NSMaxRange(closing)
        }
        return out
    }

    /// The language a `<script>`/`<style>` body is written in. Nil means "leave
    /// it to the markup rules" — a dialect with neither a grammar nor a regex
    /// table of its own.
    private static func embeddedLanguage(tag: String, attributes: String, host: Language) -> Language? {
        let attrs = parseAttributes(attributes)
        let lang = (attrs["lang"] ?? attrs["type"] ?? "").lowercased()

        if tag == "style" {
            switch lang {
            case "scss": return .scss
            case "sass": return .sass
            case "less": return .less
            case "stylus", "styl": return nil
            default: return .css  // incl. postcss, text/css, unset
            }
        }

        // JSON payload blocks (`type="application/ld+json"`, import maps, …).
        if lang.contains("json") { return .json }

        switch lang {
        case "ts", "typescript", "text/typescript": return .typescript
        case "js", "jsx", "javascript", "text/javascript", "module", "":
            // Astro compiles bare `<script>` as TypeScript; Vue/Svelte need an
            // explicit `lang="ts"`. TS is a JS superset either way, so an
            // unannotated script parses identically under both.
            return lang.isEmpty && host == .astro ? .typescript : .javascript
        default:
            return .javascript
        }
    }

    /// Attribute name → value for one opening tag's attribute text.
    private static func parseAttributes(_ source: String) -> [String: String] {
        guard let attribute, !source.isEmpty else { return [:] }
        let ns = source as NSString
        var out: [String: String] = [:]
        attribute.enumerateMatches(
            in: source, options: [],
            range: NSRange(location: 0, length: ns.length)
        ) { match, _, _ in
            guard let match else { return }
            let name = ns.substring(with: match.range(at: 1)).lowercased()
            for group in 2...4 where match.range(at: group).location != NSNotFound {
                out[name] = ns.substring(with: match.range(at: group))
                break
            }
        }
        return out
    }

    /// The parts of `clip` not covered by `covered` — i.e. the markup spans.
    static func complement(of covered: [NSRange], within clip: NSRange) -> [NSRange] {
        var gaps: [NSRange] = []
        var cursor = clip.location
        for range in TreeSitterHighlighter.mergeAscending(covered) {
            let r = NSIntersectionRange(range, clip)
            guard r.length > 0 else { continue }
            if r.location > cursor { gaps.append(NSRange(location: cursor, length: r.location - cursor)) }
            cursor = max(cursor, NSMaxRange(r))
        }
        if cursor < NSMaxRange(clip) { gaps.append(NSRange(location: cursor, length: NSMaxRange(clip) - cursor)) }
        return gaps
    }
}

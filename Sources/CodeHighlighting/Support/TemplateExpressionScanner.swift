//
//  TemplateExpressionScanner.swift
//  CodeHighlighting
//
//  The code expressions inside a component's markup: Svelte's and Astro's `{ … }`, Svelte's block
//  tags (`{#if …}`, `{@render …}`, `{#snippet name(…)}`), Vue's `{{ … }}` and directive values.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Finds the code expressions in a component's markup. Pure scanning over UTF-16 units: no regex, one pass.
enum TemplateExpressionScanner {

    /// The longest expression looked for: a `{` with no close within this many units is text.
    static let maximumLength = 20_000

    /// Svelte's expressions in `gaps` (the markup, outside `<script>` and `<style>`): `{expr}` anywhere, an
    /// attribute's `={expr}`, and the code of a block tag — the condition of `{#if}` and `{:else if}`, the list
    /// of `{#each}`, the promise of `{#await}`, `{#key}`, the bindings of `{:then}` and `{:catch}`, the
    /// signature of `{#snippet}` and the argument of `{@render}`, `{@html}`, `{@const}`, `{@debug}`, `{@attach}`.
    static func svelte(in ns: NSString, gaps: [NSRange]) -> [TemplateExpression] {
        let units = Units(ns)
        var out: [TemplateExpression] = []
        for gap in gaps {
            forEachBrace(in: units, gap: gap) { open, close in
                if let expression = svelteExpression(units, open: open, close: close) { out.append(expression) }
            }
        }
        return out
    }

    /// Astro's expressions in `gaps` (the markup after the frontmatter, outside `<script>` and `<style>`): every
    /// `{expr}` outside a quoted attribute value, where a brace is text (`data-json='{"k": 1}'`).
    static func astro(in ns: NSString, gaps: [NSRange]) -> [TemplateExpression] {
        let units = Units(ns)
        var out: [TemplateExpression] = []
        for gap in gaps {
            forEachBrace(in: units, gap: gap, skippingQuotedValues: true) { open, close in
                guard let body = trimmed(units, from: open + 1, to: close) else { return }
                out.append(expression(units, body: body, braces: braces(open, close)))
            }
        }
        return out
    }

    /// Vue's expressions in `gaps` (the template, outside `<script>` and `<style>`): every `{{ expr }}`, and the
    /// value of a directive — `v-if="…"`, `:prop="…"`, `v-bind:x="…"`, `#slot="…"` as an expression, `@click="…"`
    /// and `v-on:x="…"` as the statements of a handler, `v-for="item in list"` as a loop's head.
    static func vue(in ns: NSString, gaps: [NSRange]) -> [TemplateExpression] {
        let units = Units(ns)
        var out: [TemplateExpression] = []
        for gap in gaps {
            forEachBrace(in: units, gap: gap) { open, close in
                guard close - open >= 3, units[open + 1] == 0x7B, units[close - 1] == 0x7D,
                    let body = trimmed(units, from: open + 2, to: close - 1)
                else { return }
                let braces = [NSRange(location: open, length: 2), NSRange(location: close - 1, length: 2)]
                out.append(TemplateExpression(body: body, braces: braces, prefix: "(", suffix: ")"))
            }
            out += directives(in: units, gap: gap)
        }
        return out.sorted { $0.body.location < $1.body.location }
    }

    // MARK: - Vue directives

    /// The values of `gap`'s Vue directives (see ``vue(in:gaps:)``).
    private static func directives(in units: Units, gap: NSRange) -> [TemplateExpression] {
        var out: [TemplateExpression] = []
        var i = gap.location
        let end = NSMaxRange(gap)
        while let equals = units.find("=\"", from: i, to: end) {
            i = equals + 2
            var nameStart = equals
            while nameStart > gap.location, isNameUnit(units[nameStart - 1]) { nameStart -= 1 }
            guard nameStart < equals, nameStart > gap.location, isSpace(units[nameStart - 1]) else { continue }
            let name = units.string(nameStart, equals)
            guard let kind = directiveKind(name), let close = units.find("\"", from: equals + 2, to: min(end, equals + 2 + 2_000)),
                let body = trimmed(units, from: equals + 2, to: close)
            else { continue }
            i = close + 1
            if name == "v-for" {
                // `item in list`, `(item, index) of list`: the head of a for-in loop.
                out.append(TemplateExpression(body: body, braces: [], prefix: "for (", suffix: ");"))
                continue
            }
            out.append(TemplateExpression(body: body, braces: [], prefix: kind ? "" : "(", suffix: kind ? "" : ")"))
        }
        return out
    }

    /// For an attribute name that is a Vue directive: true when its value is a handler's statements, false when
    /// it is an expression; nil for a plain attribute.
    private static func directiveKind(_ name: String) -> Bool? {
        if name.hasPrefix("@") || name.hasPrefix("v-on:") { return true }
        if name.hasPrefix(":") || name.hasPrefix("#") || name.hasPrefix("v-") { return false }
        return nil
    }

    /// A unit of an attribute name, directive punctuation included: letters, digits, `-`, `_`, `:`, `.`, `@`,
    /// `#`, `[`, `]`.
    private static func isNameUnit(_ c: unichar) -> Bool {
        isLetter(c) || (c >= 0x30 && c <= 0x39) || c == 0x2D || c == 0x5F || c == 0x3A || c == 0x2E || c == 0x40 || c == 0x23
            || c == 0x5B || c == 0x5D
    }

    // MARK: - Svelte block tags

    /// The expression a `{ … }` holds, by its first character: a block tag's code, or the whole as an expression.
    private static func svelteExpression(_ units: Units, open: Int, close: Int) -> TemplateExpression? {
        let sigil = open + 1 < close ? units[open + 1] : 0
        guard sigil == 0x23 || sigil == 0x3A || sigil == 0x40 || sigil == 0x2F else {  // # : @ /
            guard let body = trimmed(units, from: open + 1, to: close) else { return nil }
            return expression(units, body: body, braces: braces(open, close))
        }
        guard sigil != 0x2F else { return nil }  // `{/if}` closes a block: no code
        var i = open + 2
        let wordStart = i
        while i < close, isLetter(units[i]) { i += 1 }
        let word = units.string(wordStart, i)
        guard var body = trimmed(units, from: i, to: close) else { return nil }
        switch (sigil, word) {
        case (0x3A, "else"):
            // `{:else if cond}`: the condition after `if`.
            guard units.string(body.location, min(body.location + 3, NSMaxRange(body))) == "if ",
                let condition = trimmed(units, from: body.location + 2, to: NSMaxRange(body))
            else { return nil }
            body = condition
        case (0x23, "each"):
            // `{#each list as item, index (key)}`: the list is code; the bindings are names.
            guard let end = units.find(" as ", from: body.location, to: NSMaxRange(body)),
                let list = trimmed(units, from: body.location, to: end)
            else { break }
            body = list
        case (0x23, "await"):
            // `{#await promise then value}`: the promise is the code.
            if let end = units.find(" then ", from: body.location, to: NSMaxRange(body)),
                let promise = trimmed(units, from: body.location, to: end)
            {
                body = promise
            }
        case (0x23, "snippet"):
            return TemplateExpression(body: body, braces: [], prefix: "function ", suffix: " {}")
        case (0x40, "const"):
            return TemplateExpression(body: body, braces: [], prefix: "const ", suffix: ";")
        default:
            break
        }
        return TemplateExpression(body: body, braces: [], prefix: "(", suffix: ")")
    }

    // MARK: - Braces

    /// Calls `body` with each top-level `{ … }` in `gap` — its opening and closing offsets — skipping HTML
    /// comments, and passing over the strings, template literals and comments inside an expression, so a `}` in
    /// one does not close it.
    private static func forEachBrace(
        in units: Units, gap: NSRange, skippingQuotedValues: Bool = false, _ body: (Int, Int) -> Void
    ) {
        var i = gap.location
        let end = NSMaxRange(gap)
        while i < end {
            let c = units[i]
            if skippingQuotedValues, c == 0x3D, i + 1 < end, units[i + 1] == 0x22 || units[i + 1] == 0x27 {
                i = units.find(units[i + 1] == 0x22 ? "\"" : "'", from: i + 2, to: end).map { $0 + 1 } ?? end
                continue
            }
            if c == 0x3C, units.hasPrefix("<!--", at: i) {  // an HTML comment is text, braces and all
                i = units.find("-->", from: i + 4, to: end).map { $0 + 3 } ?? end
                continue
            }
            if c == 0x7B, let close = matchingBrace(units, open: i, limit: min(end, i + maximumLength)) {
                body(i, close)
                i = close + 1
                continue
            }
            i += 1
        }
    }

    /// The `}` that closes the `{` at `open`, or nil when none does before `limit`.
    static func matchingBrace(_ units: Units, open: Int, limit: Int) -> Int? {
        // Each entry is a `{` still open: false for code, true for a template literal's `${`.
        var stack: [Bool] = []
        var i = open
        while i < limit {
            let c = units[i]
            switch c {
            case 0x7B:  // {
                stack.append(false)
            case 0x7D:  // }
                guard !stack.isEmpty else { return nil }
                let wasTemplateHole = stack.removeLast()
                if stack.isEmpty { return i }
                if wasTemplateHole {
                    guard let next = templateEnd(units, from: i + 1, limit: limit, stack: &stack) else { return nil }
                    i = next
                    continue
                }
            case 0x22, 0x27:  // " '
                i = stringEnd(units, from: i + 1, quote: c, limit: limit)
                continue
            case 0x60:  // `
                guard let next = templateEnd(units, from: i + 1, limit: limit, stack: &stack) else { return nil }
                i = next
                continue
            case 0x2F where i + 1 < limit && units[i + 1] == 0x2F:  // //
                while i < limit, units[i] != 0x0A { i += 1 }
                continue
            case 0x2F where i + 1 < limit && units[i + 1] == 0x2A:  // /*
                i = units.find("*/", from: i + 2, to: limit).map { $0 + 2 } ?? limit
                continue
            default:
                break
            }
            i += 1
        }
        return nil
    }

    /// The offset after a quoted string's closing quote; a string ends at its line's end, so an apostrophe in
    /// text inside an expression cannot pair with one lines away.
    private static func stringEnd(_ units: Units, from start: Int, quote: unichar, limit: Int) -> Int {
        var i = start
        while i < limit {
            let c = units[i]
            if c == 0x5C {
                i += 2
                continue
            }
            if c == quote { return i + 1 }
            if c == 0x0A { return i }
            i += 1
        }
        return limit
    }

    /// Walks a template literal from `start` (just inside its backtick, or just after a `${ … }` it holds):
    /// returns the offset after its closing backtick, or the offset just inside a `${`, which it pushes on
    /// `stack` so the matching `}` resumes the literal. Nil when it never closes.
    private static func templateEnd(_ units: Units, from start: Int, limit: Int, stack: inout [Bool]) -> Int? {
        var i = start
        while i < limit {
            let c = units[i]
            if c == 0x5C {
                i += 2
                continue
            }
            if c == 0x60 { return i + 1 }
            if c == 0x24, i + 1 < limit, units[i + 1] == 0x7B {
                stack.append(true)
                return i + 2
            }
            i += 1
        }
        return nil
    }

    // MARK: - Helpers

    /// A `{ … }` body as the fragment it parses as: a spread (`{...rest}`) inside an array literal, a lone comment
    /// (`{/* note */}`) as it is, anything else inside parentheses.
    private static func expression(_ units: Units, body: NSRange, braces: [NSRange]) -> TemplateExpression {
        if units.hasPrefix("...", at: body.location) {
            return TemplateExpression(body: body, braces: braces, prefix: "[", suffix: "]")
        }
        if units.hasPrefix("/*", at: body.location) || units.hasPrefix("//", at: body.location) {
            return TemplateExpression(body: body, braces: braces, prefix: "", suffix: "")
        }
        return TemplateExpression(body: body, braces: braces, prefix: "(", suffix: ")")
    }

    /// `from..<to` without its surrounding whitespace; nil when nothing is left.
    private static func trimmed(_ units: Units, from: Int, to: Int) -> NSRange? {
        var a = from
        var b = to
        while a < b, isSpace(units[a]) { a += 1 }
        while b > a, isSpace(units[b - 1]) { b -= 1 }
        return b > a ? NSRange(location: a, length: b - a) : nil
    }

    private static func braces(_ open: Int, _ close: Int) -> [NSRange] {
        [NSRange(location: open, length: 1), NSRange(location: close, length: 1)]
    }

    private static func isLetter(_ c: unichar) -> Bool { (c >= 0x61 && c <= 0x7A) || (c >= 0x41 && c <= 0x5A) }

    private static func isSpace(_ c: unichar) -> Bool { c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D }

    /// A document's UTF-16 units, read once.
    struct Units {
        private let buffer: [unichar]

        init(_ ns: NSString) {
            var buffer = [unichar](repeating: 0, count: ns.length)
            ns.getCharacters(&buffer, range: NSRange(location: 0, length: ns.length))
            self.buffer = buffer
        }

        var count: Int { buffer.count }

        subscript(_ i: Int) -> unichar { buffer[i] }

        /// The units `from..<to` as a string.
        func string(_ from: Int, _ to: Int) -> String {
            guard to > from else { return "" }
            return String(utf16CodeUnits: Array(buffer[from..<to]), count: to - from)
        }

        /// Whether `text` (ASCII) starts at `i`.
        func hasPrefix(_ text: String, at i: Int) -> Bool {
            let needle = Array(text.utf16)
            guard i + needle.count <= buffer.count else { return false }
            for (k, u) in needle.enumerated() where buffer[i + k] != u { return false }
            return true
        }

        /// The first offset in `from..<to` where `text` (ASCII) starts, or nil.
        func find(_ text: String, from: Int, to: Int) -> Int? {
            let needle = Array(text.utf16)
            guard let first = needle.first, to - needle.count >= from else { return nil }
            var i = from
            while i + needle.count <= to {
                if buffer[i] == first, hasPrefix(text, at: i) { return i }
                i += 1
            }
            return nil
        }
    }
}

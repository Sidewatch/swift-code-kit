//
//  MarkupOutline.swift
//  CodeHighlighting
//
//  Outlines for HTML and the templates built on it: headings, ids and landmarks, plus the
//  outline of the code each file carries.
//
//  Created by David Sherlock on 10/4/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation
import CodeLanguage

/// Outlines for HTML and the templates built on it (Vue, Svelte, Astro, Razor, ERB, EJS, JSP):
///
/// - the page's structure: headings `h1`–`h6` by their text, nested by level within the element
///   that holds them; elements with an `id` as `#id`; the landmarks `header`, `nav`, `main`,
///   `footer` and `aside`; and, in a component, the custom components near the top of its markup;
/// - the code it carries: each `<script>` and `<style>` body (and Astro's frontmatter) outlined in
///   its own language under a `script` / `style` / `frontmatter` entry; Razor's `@code` and
///   `@functions` members and its `@section`s; JSP's `<%! … %>` members; the functions and classes
///   defined inside ERB and EJS tags.
///
/// The markup is read with a tolerant tag scanner, not a parser: an element left open is closed by
/// its parent, which is what browsers do with `<p>` and `<li>`.
public enum MarkupOutline {
    /// The languages this outlines.
    static let hosts: Set<Language> = [.html, .vue, .svelte, .astro, .razor, .erb, .ejs, .jsp]

    /// Whether `language` takes its outline from here.
    public static func supports(_ language: Language) -> Bool { hosts.contains(language) }

    /// The outline symbols of `text`, in document order and scoped for ``OutlineTree``.
    public static func symbols(in text: String, language: Language) -> [Symbol] {
        let ns = text as NSString
        guard ns.length > 0, hosts.contains(language) else { return [] }
        let lines = OutlineLines(ns)
        var out: [Symbol] = []
        var skipped: [NSRange] = []  // code the markup scan must not read as tags

        for region in codeRegions(in: ns, language: language) {
            skipped.append(region.span)
            let body = ns.substring(with: region.body)
            var inner: [Symbol]
            if let wrapper = region.wrapper {
                let wrapped = wrapper.prefix + body + wrapper.suffix
                inner = DocumentOutline.symbols(parsing: wrapped, language: region.language).filter { $0.name != wrapper.name }
                let prefixLength = (wrapper.prefix as NSString).length
                let prefixLines = wrapper.prefix.filter { $0 == "\n" }.count
                inner = lines.moved(inner, to: region.body.location, textOffset: prefixLength, textLines: prefixLines)
            } else {
                inner = lines.moved(DocumentOutline.symbols(parsing: body, language: region.language), to: region.body.location)
            }
            guard !inner.isEmpty else { continue }
            guard !region.title.isEmpty else {
                out += inner
                continue
            }
            out.append(
                Symbol(
                    name: region.title, kind: .module, range: region.titleRange, line: lines.index(of: region.titleRange.location) + 1,
                    scopeRange: region.span))
            out += inner
        }
        let sections = razorSections(in: ns, language: language, lines: lines)
        out += sections
        out += fragmentSymbols(in: ns, language: language, lines: lines)
        // Code (script, style, frontmatter, @code, a JSP declaration) and a Razor @section belong to
        // the page, not to the heading before them: headings stop where one starts.
        let barriers = (skipped.map(\.location) + sections.compactMap { $0.scopeRange?.location }).sorted()
        out += elementSymbols(in: ns, language: language, skipping: skipped, barriers: barriers, lines: lines)
        // Document order; at one offset the wider scope (the container) comes first.
        return out.sorted {
            $0.range.location != $1.range.location
                ? $0.range.location < $1.range.location : ($0.scopeRange?.length ?? 0) > ($1.scopeRange?.length ?? 0)
        }
    }

    // MARK: - Code regions

    /// Code the file carries, outlined in its own language.
    struct CodeRegion {
        /// The whole element or block, delimiters included: the container's scope.
        let span: NSRange
        /// The code itself.
        let body: NSRange
        let language: Language
        /// The container's name in the outline (`script`, `style`, `frontmatter`, `@code`).
        let title: String
        /// Where that name sits: the tag name or directive.
        let titleRange: NSRange
        /// Text wrapped around the body so its grammar parses it (Razor's members need a class);
        /// `name` is the wrapper's own symbol, dropped from the result.
        var wrapper: (prefix: String, suffix: String, name: String)? = nil
    }

    /// The code regions of `ns`, in order.
    static func codeRegions(in ns: NSString, language: Language) -> [CodeRegion] {
        switch language {
        case .razor: return razorCodeBlocks(in: ns)
        case .jsp: return jspDeclarations(in: ns)
        case .erb, .ejs: return []  // their code is in short tags, read by `fragmentSymbols`
        default: break
        }
        var out: [CodeRegion] = []
        for region in EmbeddedMarkupHighlighter.regions(in: ns, language: language) {
            // A JSON-LD block or an import map is data, not code: no outline of its keys.
            if region.language == .json || region.language == .jsonc { continue }
            let body = region.range
            // Astro's frontmatter: the `---` fences around the body.
            if language == .astro, body.location < 8, ns.substring(to: body.location).contains("---") {
                let close = ns.range(
                    of: "---", options: [], range: NSRange(location: NSMaxRange(body), length: ns.length - NSMaxRange(body)))
                let end = close.location == NSNotFound ? NSMaxRange(body) : NSMaxRange(close)
                let open = ns.range(of: "---")
                out.append(
                    CodeRegion(
                        span: NSRange(location: 0, length: end), body: body, language: region.language, title: "frontmatter",
                        titleRange: open.location == NSNotFound ? NSRange(location: 0, length: 0) : open))
                continue
            }
            // The tag that opens the body: the last `<` before it.
            let lt = ns.range(of: "<", options: .backwards, range: NSRange(location: 0, length: body.location))
            guard lt.location != NSNotFound else { continue }
            let tagText = ns.substring(with: NSRange(location: lt.location + 1, length: body.location - lt.location - 1))
            let tag = String(tagText.prefix { $0.isLetter }).lowercased()
            guard !tag.isEmpty else { continue }
            let closing = ns.range(
                of: ">", options: [],
                range: NSRange(location: NSMaxRange(body), length: ns.length - NSMaxRange(body)))
            let end = closing.location == NSNotFound ? ns.length : NSMaxRange(closing)
            var title = tag
            if tag == "script", tagText.range(of: #"\bsetup\b"#, options: .regularExpression) != nil { title = "script setup" }
            out.append(
                CodeRegion(
                    span: NSRange(location: lt.location, length: end - lt.location), body: body, language: region.language, title: title,
                    titleRange: NSRange(location: lt.location + 1, length: (tag as NSString).length)))
        }
        return out
    }

    /// Razor's `@code { … }`, `@functions { … }` and `@{ … }` blocks. The first two carry members,
    /// parsed as C# inside a class; `@{ … }` is skipped by the markup scan and lists nothing.
    private static func razorCodeBlocks(in ns: NSString) -> [CodeRegion] {
        guard let opener = try? NSRegularExpression(pattern: #"@(code|functions)?[ \t]*\{"#) else { return [] }
        var out: [CodeRegion] = []
        var from = 0
        while from < ns.length, let m = opener.firstMatch(in: ns as String, range: NSRange(location: from, length: ns.length - from)) {
            let open = NSMaxRange(m.range) - 1
            guard let close = matchingBrace(in: ns, open: open) else { break }
            let body = NSRange(location: open + 1, length: close - open - 1)
            let span = NSRange(location: m.range.location, length: close + 1 - m.range.location)
            let keyword = m.range(at: 1)
            if keyword.location != NSNotFound {
                out.append(
                    CodeRegion(
                        span: span, body: body, language: .csharp, title: "@" + ns.substring(with: keyword),
                        titleRange: NSRange(location: m.range.location, length: keyword.length + 1),
                        wrapper: ("class __RazorCode {\n", "\n}", "__RazorCode")))
            } else {
                out.append(CodeRegion(span: span, body: body, language: .plainText, title: "@", titleRange: m.range))
            }
            from = close + 1
        }
        return out
    }

    /// JSP's `<%! … %>` declarations: the page class's members, parsed as Java inside a class and
    /// listed at the top level (no container entry; `title` is empty).
    private static func jspDeclarations(in ns: NSString) -> [CodeRegion] {
        guard let declaration = try? NSRegularExpression(pattern: #"<%!([\s\S]*?)%>"#) else { return [] }
        return declaration.matches(in: ns as String, range: NSRange(location: 0, length: ns.length)).map { m in
            CodeRegion(
                span: m.range, body: m.range(at: 1), language: .java, title: "", titleRange: m.range,
                wrapper: ("class __JspPage {\n", "\n}", "__JspPage"))
        }
    }

    /// Razor's `@section Name { … }`: an entry holding the markup inside it.
    private static func razorSections(in ns: NSString, language: Language, lines: OutlineLines) -> [Symbol] {
        guard language == .razor, let section = try? NSRegularExpression(pattern: #"@section[ \t]+([A-Za-z_]\w*)[ \t]*\{"#) else {
            return []
        }
        return section.matches(in: ns as String, range: NSRange(location: 0, length: ns.length)).map { m in
            let open = NSMaxRange(m.range) - 1
            let close = matchingBrace(in: ns, open: open) ?? (ns.length - 1)
            return Symbol(
                name: "section " + ns.substring(with: m.range(at: 1)), kind: .module, range: m.range(at: 1),
                line: lines.index(of: m.range.location) + 1,
                scopeRange: NSRange(location: m.range.location, length: close + 1 - m.range.location))
        }
    }

    /// The `}` matching the `{` at `open`, strings and comments skipped; nil when unbalanced.
    static func matchingBrace(in ns: NSString, open: Int) -> Int? {
        var depth = 0
        var i = open
        let length = ns.length
        while i < length {
            let c = ns.character(at: i)
            switch c {
            case 0x22, 0x27:  // " ' — a literal
                var j = i + 1
                while j < length, ns.character(at: j) != c, ns.character(at: j) != 0x0A {
                    if ns.character(at: j) == 0x5C { j += 1 }
                    j += 1
                }
                i = j
            case 0x2F where i + 1 < length && ns.character(at: i + 1) == 0x2F:  // // comment
                while i < length, ns.character(at: i) != 0x0A { i += 1 }
            case 0x2F where i + 1 < length && ns.character(at: i + 1) == 0x2A:  // /* comment */
                let end = ns.range(of: "*/", options: [], range: NSRange(location: i + 2, length: length - i - 2))
                i = end.location == NSNotFound ? length : NSMaxRange(end) - 1
            case 0x7B: depth += 1
            case 0x7D:
                depth -= 1
                if depth == 0 { return i }
            default: break
            }
            i += 1
        }
        return nil
    }

    // MARK: - Template code fragments

    /// The functions and classes defined inside ERB and EJS tags (`<% def total %>`,
    /// `<% function row(o) { %>`). Flat: a fragment rarely holds a whole definition, so there is no
    /// body to nest under. (JSP's declarations are parsed as Java: see `jspDeclarations`.)
    private static func fragmentSymbols(in ns: NSString, language: Language, lines: OutlineLines) -> [Symbol] {
        let patterns: [(String, SymbolKind)]
        switch language {
        case .erb:
            patterns = [
                (#"\bdef[ \t]+((?:self\.)?[A-Za-z_]\w*[?!=]?)"#, .function),
                (#"\bclass[ \t]+([A-Z]\w*(?:::\w+)*)"#, .type),
                (#"\bmodule[ \t]+([A-Z]\w*(?:::\w+)*)"#, .module),
                (#"\bcontent_for[ \t(]+(:\w+)"#, .module),
            ]
        case .ejs:
            patterns = [
                (#"\bfunction[ \t]+([A-Za-z_$][\w$]*)"#, .function),
                (
                    #"\b(?:const|let|var)[ \t]+([A-Za-z_$][\w$]*)[ \t]*=[ \t]*(?:async[ \t]*)?(?:function\b|\([^)\n]*\)[ \t]*=>|[A-Za-z_$][\w$]*[ \t]*=>)"#,
                    .function
                ),
                (#"\bclass[ \t]+([A-Za-z_$][\w$]*)"#, .type),
            ]
        default: return []
        }
        // ERB and EJS run code in `<% … %>` (`<%=` prints, `<%#` is a comment).
        guard let fragment = try? NSRegularExpression(pattern: #"<%(?![=#-])([\s\S]*?)%>"#) else { return [] }
        let compiled = patterns.compactMap { p in (try? NSRegularExpression(pattern: p.0)).map { ($0, p.1) } }
        let keywords: Set<String> = ["if", "for", "while", "switch", "catch", "return", "new"]
        var out: [Symbol] = []
        for f in fragment.matches(in: ns as String, range: NSRange(location: 0, length: ns.length)) {
            let body = f.range(at: 1)
            // Matched with its string literals blanked, so "class init" in a message is not a class.
            let code = blankingStrings(ns.substring(with: body))
            for (regex, kind) in compiled {
                for m in regex.matches(in: code, range: NSRange(location: 0, length: (code as NSString).length)) {
                    let inner = m.range(at: 1)
                    guard inner.location != NSNotFound else { continue }
                    let name = NSRange(location: body.location + inner.location, length: inner.length)
                    guard !keywords.contains(ns.substring(with: name)) else { continue }
                    out.append(Symbol(name: ns.substring(with: name), kind: kind, range: name, line: lines.index(of: name.location) + 1))
                }
            }
        }
        return out.sorted { $0.range.location < $1.range.location }
    }

    /// `code` with the contents of its `"…"` and `'…'` literals replaced by spaces, same length.
    private static func blankingStrings(_ code: String) -> String {
        var units = Array(code.utf16)
        var i = 0
        while i < units.count {
            let q = units[i]
            guard q == 0x22 || q == 0x27 else { i += 1; continue }
            var j = i + 1
            while j < units.count, units[j] != q, units[j] != 0x0A {
                if units[j] == 0x5C, j + 1 < units.count { units[j] = 0x20; j += 1 }
                units[j] = 0x20
                j += 1
            }
            i = j + 1
        }
        return String(decoding: units, as: UTF16.self)
    }

    // MARK: - Markup

    /// One tag of the markup: `<name attrs>`, `</name>` or `<!-- … -->` (group 1 empty).
    private static let tag = try? NSRegularExpression(
        pattern: #"<!--[\s\S]*?-->|<(/?)([A-Za-z][\w:.-]*)((?:[^>"']|"[^"]*"|'[^']*')*)>"#)
    /// A static `id="…"` (not `:id`, `v-bind:id` or `data-id`).
    private static let idAttribute = try? NSRegularExpression(pattern: #"(?:^|[\s/])id[ \t]*=[ \t]*(?:"([^"]*)"|'([^']*)')"#)
    /// `aria-label="…"`, which names a landmark (`nav (Primary)`).
    private static let ariaLabel = try? NSRegularExpression(pattern: #"\baria-label[ \t]*=[ \t]*(?:"([^"]*)"|'([^']*)')"#)
    /// Elements with no closing tag.
    private static let voids: Set<String> = [
        "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr", "keygen",
    ]
    private static let landmarks: Set<String> = ["header", "nav", "main", "footer", "aside"]

    /// An element the scan has opened and not yet closed.
    private struct Open {
        let name: String
        let start: Int
        /// The index in `out` of the element's own symbol, if it has one.
        let symbol: Int?
    }

    /// Headings, ids, landmarks and top components of the markup outside `skipping`.
    private static func elementSymbols(
        in ns: NSString, language: Language, skipping: [NSRange], barriers: [Int], lines: OutlineLines
    ) -> [Symbol] {
        guard let tag else { return [] }
        let component = language == .vue || language == .svelte || language == .astro
        var out: [Symbol] = []
        var scopes: [NSRange?] = []
        var stack: [Open] = []
        // A heading's level and the element holding it (an index into `closes`), resolved at the end.
        var headings: [(symbol: Int, level: Int, parent: Int?)] = []
        var closes: [Int] = []  // per opened element: where it closed (set when it does)
        var openIDs: [Int] = []  // `closes` index of each element on `stack`
        var skip = 0
        var seenComponents: Set<String> = []  // a component is listed where it is first used

        for m in tag.matches(in: ns as String, range: NSRange(location: 0, length: ns.length)) {
            while skip < skipping.count, NSMaxRange(skipping[skip]) <= m.range.location { skip += 1 }
            if skip < skipping.count, NSLocationInRange(m.range.location, skipping[skip]) { continue }
            let nameRange = m.range(at: 2)
            guard nameRange.location != NSNotFound else { continue }  // a comment
            let name = ns.substring(with: nameRange)
            let lower = name.lowercased()
            if m.range(at: 1).length > 0 {  // </name>: close it and whatever it left open
                guard let at = stack.lastIndex(where: { $0.name == lower }) else { continue }
                for k in stride(from: stack.count - 1, through: at, by: -1) {
                    let end = k == at ? NSMaxRange(m.range) : m.range.location
                    if let s = stack[k].symbol { scopes[s] = NSRange(location: stack[k].start, length: end - stack[k].start) }
                    closes[openIDs[k]] = end
                }
                stack.removeSubrange(at...)
                openIDs.removeSubrange(at...)
                continue
            }
            let attrs = ns.substring(with: m.range(at: 3))
            let line = lines.index(of: m.range.location) + 1
            var symbol: Int?
            let depth = stack.filter { $0.name != "template" }.count

            if lower.count == 2, lower.hasPrefix("h"), let level = Int(lower.dropFirst()), (1...6).contains(level) {
                let title = headingText(in: ns, after: NSMaxRange(m.range), level: level) ?? idValue(attrs) ?? lower
                out.append(Symbol(name: title, kind: .heading, range: nameRange, line: line))
                scopes.append(nil)
                symbol = out.count - 1
                headings.append((out.count - 1, level, openIDs.last))
            } else if let id = idValue(attrs) {
                out.append(Symbol(name: "#" + id, kind: .selector, range: nameRange, line: line))
                scopes.append(nil)
                symbol = out.count - 1
            } else if landmarks.contains(lower) {
                let label = firstGroup(ariaLabel, in: attrs).map { " (\($0))" } ?? ""
                out.append(Symbol(name: lower + label, kind: .module, range: nameRange, line: line))
                scopes.append(nil)
                symbol = out.count - 1
            } else if language == .vue, lower == "template", stack.isEmpty {
                out.append(Symbol(name: "template", kind: .module, range: nameRange, line: line))
                scopes.append(nil)
                symbol = out.count - 1
            } else if component, depth <= 2, isCustomComponent(name), seenComponents.insert(name).inserted {
                out.append(Symbol(name: name, kind: .type, range: nameRange, line: line))
                scopes.append(nil)
                symbol = out.count - 1
            }

            if attrs.hasSuffix("/") || voids.contains(lower) {
                if let symbol { scopes[symbol] = m.range }
                continue
            }
            closes.append(ns.length)
            openIDs.append(closes.count - 1)
            stack.append(Open(name: lower, start: m.range.location, symbol: symbol))
        }
        for k in stack.indices {
            if let s = stack[k].symbol { scopes[s] = NSRange(location: stack[k].start, length: ns.length - stack[k].start) }
        }

        // Headings hold what follows them up to the next heading of the same or a higher level,
        // never past the end of the element that holds them.
        for (i, h) in headings.enumerated() {
            let start = lines.starts[out[h.symbol].line - 1]
            var end = h.parent.map { closes[$0] } ?? ns.length
            for next in headings[(i + 1)...] where next.level <= h.level {
                end = min(end, lines.starts[out[next.symbol].line - 1])
                break
            }
            if let barrier = barriers.first(where: { $0 > out[h.symbol].range.location }) { end = min(end, barrier) }
            scopes[h.symbol] = NSRange(location: start, length: max(out[h.symbol].range.length, end - start))
        }
        return out.indices.map { i in
            let s = out[i]
            return Symbol(name: s.name, kind: s.kind, range: s.range, line: s.line, scopeRange: scopes[i])
        }
    }

    /// The text of the heading that opens at `start`: up to its `</hN>`, tags stripped, entities
    /// decoded, whitespace collapsed, at most 80 characters. Nil when it is empty.
    private static func headingText(in ns: NSString, after start: Int, level: Int) -> String? {
        let close = ns.range(
            of: "</h\(level)", options: .caseInsensitive, range: NSRange(location: start, length: min(ns.length - start, 2000)))
        guard close.location != NSNotFound else { return nil }
        var text = ns.substring(with: NSRange(location: start, length: close.location - start))
        // `<%= expr %>` reads as its expression; real tags go.
        text = text.replacingOccurrences(of: #"<%[=-]?\s*([\s\S]*?)\s*-?%>"#, with: "$1", options: .regularExpression)
        text = text.replacingOccurrences(of: #"<[A-Za-z/!][^>]*>"#, with: "", options: .regularExpression)
        for (entity, char) in [("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""), ("&#39;", "'"), ("&nbsp;", " ")] {
            text = text.replacingOccurrences(of: entity, with: char)
        }
        let collapsed = text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        guard !collapsed.isEmpty else { return nil }
        return collapsed.count > 80 ? String(collapsed.prefix(79)) + "…" : collapsed
    }

    /// The element's static id, unless it is computed by the template (`{x}`, `<%= x %>`, `@x`).
    private static func idValue(_ attrs: String) -> String? {
        guard let value = firstGroup(idAttribute, in: attrs), !value.isEmpty,
            !value.contains("{"), !value.contains("<"), !value.hasPrefix("@"), !value.contains("$")
        else { return nil }
        return value
    }

    /// The first non-empty capture of `regex` in `text`.
    private static func firstGroup(_ regex: NSRegularExpression?, in text: String) -> String? {
        let ns = text as NSString
        guard let regex, let m = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) else { return nil }
        for g in 1..<m.numberOfRanges where m.range(at: g).location != NSNotFound { return ns.substring(with: m.range(at: g)) }
        return nil
    }

    /// A component: a capitalised tag (`<OrderTable>`, `<Card.Header>`) or a custom element
    /// (`<order-table>`), not a namespaced built-in (`<svelte:head>`, `<svg:rect>`).
    private static func isCustomComponent(_ name: String) -> Bool {
        guard !name.contains(":"), let first = name.first else { return false }
        return first.isUppercase || name.contains("-")
    }
}

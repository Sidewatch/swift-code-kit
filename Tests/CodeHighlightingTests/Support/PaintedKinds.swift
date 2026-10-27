//
//  PaintedKinds.swift
//  CodeHighlightingTests
//
//  A text painted by a language's rule table, read back as the token kind at each place.
//
//  Created by David Sherlock on 10/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import CodeLanguage

@testable import CodeHighlighting

/// A text painted by a language's rule table (``SyntaxHighlighter``) with one marker colour per token kind,
/// so each character reads back as the kind it was painted; plain text and identifiers read back as nil.
@MainActor
struct PaintedKinds {
    private let storage: NSTextStorage

    init(_ text: String, _ language: Language) {
        storage = NSTextStorage(string: text)
        SyntaxHighlighter(language: language, colors: Markers()).highlight(storage, in: NSRange(location: 0, length: storage.length))
    }

    /// The kind painted `offset` characters into the first occurrence of `needle`; nil where it is plain, or
    /// when the text has no `needle`.
    func kind(_ needle: String, _ offset: Int = 0) -> TokenKind? {
        let found = (storage.string as NSString).range(of: needle)
        guard found.location != NSNotFound else { return nil }
        return kind(at: found.location + offset)
    }

    /// The kinds painted along the first occurrence of `needle`, one per UTF-16 unit; empty when the text
    /// has no `needle`.
    func kinds(along needle: String) -> [TokenKind?] {
        let found = (storage.string as NSString).range(of: needle)
        guard found.location != NSNotFound else { return [] }
        return (found.location..<NSMaxRange(found)).map(kind(at:))
    }

    private func kind(at location: Int) -> TokenKind? {
        guard location < storage.length, let color = storage.attribute(.foregroundColor, at: location, effectiveRange: nil) as? NSColor
        else { return nil }
        return Markers.kind(of: color)
    }
}

/// One unique colour per token kind, so a painted run reverse-maps to its kind.
private struct Markers: TokenColorProviding {
    static let kinds: [TokenKind] = [.comment, .string, .keyword, .type, .number, .function, .attribute, .variable, .property]

    func color(for kind: TokenKind) -> NSColor {
        if kind == .identifier { return foreground }
        return NSColor(deviceRed: CGFloat((Self.kinds.firstIndex(of: kind) ?? -1) + 1) / 100, green: 0, blue: 0, alpha: 1)
    }

    var foreground: NSColor { NSColor(deviceRed: 0, green: 0, blue: 0, alpha: 1) }

    static func kind(of color: NSColor) -> TokenKind? {
        guard let c = color.usingColorSpace(.deviceRGB) else { return nil }
        let i = Int(round(c.redComponent * 100)) - 1
        return kinds.indices.contains(i) ? kinds[i] : nil
    }
}

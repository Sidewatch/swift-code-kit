//
//  RuleTables+InterpolatedStrings.swift
//  CodeHighlighting
//
//  String literals whose interpolations stay code: JavaScript's `${ … }`, Ruby's `#{ … }`.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// String literals whose interpolations keep code colours, as VS Code paints them. A literal on one
/// line whose interpolations hold no brace, quote or line break paints as string pieces — the text
/// before the first interpolation, and each run after its `}` up to the next interpolation or the
/// closing quote. Any other literal (one spanning lines, or nesting braces or literals) paints whole.
/// A quote right after a `}` closes an interpolated literal and never opens one.
///
/// Strings are matched from where the last one ended, so a lookbehind there sees nothing before that
/// point: the pieces after an interpolation are found inside a scope (``inside(opens:closes:within:)``,
/// whose regions are found over the whole text) and look back one character only.
extension RuleTables {

    /// JavaScript template literals, `` `a ${b} c` `` (Marko, MDX).
    static let templateLiteralStrings = interpolatedStrings(quote: "`", sigil: "\\$")

    /// A template literal's head and whole-literal rules without the pieces after its holes, for a table
    /// that finds those pieces in one pass with its own (Razor).
    static let templateLiteralHeads = Array(templateLiteralStrings.prefix(2))

    /// One character of a template literal's text (``literalText(quote:sigil:)``).
    static let templateLiteralText = literalText(quote: "`", sigil: "\\$")

    /// Inside a template literal on one line whose holes are simple (``insideSimpleLiteral(quote:sigil:)``).
    static let insideSimpleTemplateLiteral = insideSimpleLiteral(quote: "`", sigil: "\\$")

    /// The three string rules for literals quoted by `quote` whose interpolations open with `sigil` and
    /// a `{` (both regex forms, `quote` one character): the head (or a whole simple literal), a literal
    /// painted whole, and the pieces after each interpolation. `scope` (markers, or empty) limits where
    /// a literal may open; a literal painted whole spans lines only when `multiline` is true.
    static func interpolatedStrings(quote q: String, sigil: String, scope: String = "", multiline: Bool = true) -> [(String, TokenKind)] {
        let text = literalText(quote: q, sigil: sigil)
        let interpolation = simpleInterpolation(quote: q, sigil: sigil)
        let whole = multiline ? "(?:[^\(q)\\\\]|\\\\[\\s\\S])*" : "(?:[^\(q)\\\\\\n]|\\\\.)*"
        return [
            (scope + "\(q)(?<!\\}\(q))(?:\(text))*(?:\(q)|(?=\(interpolation)(?:\(text)|\(interpolation))*\(q)))", .string),
            (scope + "\(q)(?<!\\}\(q))(?!(?:\(text)|\(interpolation))*\(q))\(whole)\(q)", .string),
            (insideSimpleLiteral(quote: q, sigil: sigil) + tailPiece(text: text, quote: q, sigil: sigil), .string),
        ]
    }

    /// One character of a literal's text on its line: not the quote, an escape, or a `sigil` that opens
    /// no interpolation.
    static func literalText(quote q: String, sigil: String) -> String {
        "[^\(q)\\\\\(sigil)\\n]|\\\\.|\(sigil)(?!\\{)"
    }

    /// An interpolation with no brace, quote or line break inside.
    static func simpleInterpolation(quote q: String, sigil: String) -> String {
        "\(sigil)\\{[^{}\(q)\\n]*\\}"
    }

    /// The scope of a literal on one line whose interpolations are all simple.
    static func insideSimpleLiteral(quote q: String, sigil: String) -> String {
        let text = literalText(quote: q, sigil: sigil)
        return inside(opens: ["\(q)(?:\(text)|\(simpleInterpolation(quote: q, sigil: sigil)))*\(q)"], closes: [""], within: 0)
    }

    /// The text after an interpolation's `}` (`text`, a regex alternation of one character's forms) up to
    /// the closing `quote` or the next `sigil{`, or that quote alone.
    static func tailPiece(text: String, quote q: String, sigil: String) -> String {
        "(?<=\\})(?:(?:\(text))++(?:\(q)|(?=\(sigil)\\{))|\(q))"
    }
}

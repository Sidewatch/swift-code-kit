//
//  SlimRules.swift
//  CodeHighlighting
//
//  The regex rule table for Slim.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Slim: `/` code comments and `/!` HTML comments with the lines nested under them; tags, `.class` and
/// `#id` shorthands, attributes; `-` / `=` Ruby lines with their keywords, symbols and `key:` hash
/// keys; strings, whose `#{…}` interpolations stay code; numbers. A `|` or `'` line and a tag's inline
/// text are text, so a quote in them opens no string.
/// Later rules repaint earlier ones; strings and comments paint last.
extension RuleTables {
    static let slim: [(String, TokenKind)] =
        [
            // `/` opens a code comment and `/!` an HTML comment, each to the end of its line and over every
            // line indented deeper below it; `/[if IE]` opens a conditional one, its line only, whose nested
            // markup is rendered.
            ("^([ \\t]*)/(?!\\[).*(?:\\n\\1[ \\t]+\\S.*|\\n[ \\t]*(?=\\n))*", .comment),
            ("#\\{[^}\\n]*\\}", .property),
            // Quotes delimit attribute values and Ruby strings, which end on their line: anywhere on a Ruby
            // line or in an interpolation, and on a tag line where a value or an expression starts (after
            // `=`, `(`, `[`, `,`, `|`, `<` or `>`), so a quote in a tag's inline text (`p say "hi"`) is text.
            (rubyLine + interpolation + "'(?:[^'\\\\\\n]|\\\\.)*'", .string),
            ("'(?<=[=(\\[,|<>][ \\t]?')(?:[^'\\\\\\n]|\\\\.)*'", .string),
        ] + rubyStringPieces(multiline: false, skip: ["'(?:[^'\\\\\\n]|\\\\.)*'"], scope: rubyLine + valueStart + interpolation) + [
            // A Ruby symbol (`as: :item`, `params[:q]`, `&:qty`) after a space, bracket, comma or `&`, and a
            // hash key (`count: n`) on a code line.
            ("(?<=[\\s(\\[,{&]):[A-Za-z_]\\w*[?!]?", .string),
            (codeLine + "\\b[a-z_]\\w*(?=:[ \\t])", .string),
            ("^\\s*[|']", .keyword),
            ("^\\s*(doctype)\\b.*$", .keyword),
            (
                "\\b(if|else|elsif|unless|each|for|in|while|case|when|do|end|yield|render|javascript|css|coffee|markdown|sass|scss|ruby)\\b",
                .keyword
            ),
            (rubyLine + "\\b(?:begin|rescue|ensure|raise|until|retry|next|break|loop|then|and|or|not)\\b", .keyword),
            ("^\\s*[a-z][\\w:-]*(?=[\\s.#(\\[=:<>]|$)", .keyword),
            ("[.#][A-Za-z_][\\w-]*", .type),
            ("\\b[\\w:-]+(?==)", .property),
            ("^\\s*[-=]=?[<>]?", .variable),
            ("\\b\\d[\\d_]*(\\.\\d+)?\\b", .number),
        ]

    /// A quote where a value or an expression starts on a tag line: after `=`, `(`, `[`, `,`, `|`, `<`
    /// or `>` and an optional space.
    private static let valueStart = inside(opens: ["(?<=[=(\\[,|<>])[ \\t]?[\"']"], closes: [""], within: 0)

    /// Inside a `#{ … }` interpolation.
    private static let interpolation = inside(opens: ["#\\{"], closes: ["\\}"], within: 200)

    /// A Ruby line or a tag's code.
    private static let rubyLine = codeLine + tagCode

    /// A line of Ruby: from a leading `-`, `=` or `==` to the line's end.
    private static let codeLine = inside(opens: ["(?m)^[ \\t]*[-=]"], closes: ["\\n"], within: 400)

    /// A tag's code: from its `=` (`p.total = sum`, `p=> x`) to the line's end.
    private static let tagCode = inside(
        opens: ["(?m)^[ \\t]*[A-Za-z.#][\\w.#:-]*[ \\t]*==?[<>]?(?=[ \\t])"], closes: ["\\n"], within: 400)
}

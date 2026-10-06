//
//  CrystalRules.swift
//  CodeHighlighting
//
//  The regex rule table for Crystal.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Crystal: `"…"` whose `#{ … }` and `{{ … }}` holes stay code after the `#` (and may hold quotes and braces of
/// their own), `<<-HEREDOC` bodies, `/regex/flags`, `%(…)` `%Q(…)` `%q[…]` `%w{…}` `%i<…>` `%r|…|` percent
/// literals (painted whole, holes included), `` `command` ``, `'c'` chars (escapes included, `'\''`), `:symbols`, the language's keywords
/// (`.is_a?`, `.as?` and `.responds_to?` with their dot), the type a `class` / `struct` / `module` / `enum` /
/// `lib` / `annotation` / `union` / `alias` / `type` declares (with its type parameters, `Store(T)`) or
/// inherits (`< Base`), and the method a `def`, `macro` or `fun` declares, operator methods included.
extension RuleTables {
    static let crystal: [(String, TokenKind)] =
        quotedStringPieces(
            quote: "\"", body: "[^\"\\\\]|\\\\[\\s\\S]", hole: crystalHole, holeEnd: "\\}",
            afterHole: "(?<=\\})")
        + [
            ("'(?:\\\\(?:u\\{[0-9a-fA-F]+\\}|u[0-9a-fA-F]{4}|x[0-9a-fA-F]{2}|[0-7]{1,3}|[^\\n])|[^'\\\\\\n])'", .string),
            backQuoted,
            ("(?<![\\w)\\]}.])/(?![\\s/=])(?:[^/\\\\\\n]|\\\\.)+/[imx]*", .string),
            ("<<-(['\"]?)([A-Za-z_]\\w*)\\1[^\\n]*\\n[\\s\\S]*?^[ \\t]*\\2\\b", .string),
            (
                "%[qQwiIrx]?(?:\\((?:[^()\\\\]|\\\\.|\\([^()]*\\))*\\)|\\[(?:[^\\[\\]\\\\]|\\\\.|\\[[^\\[\\]]*\\])*\\]|\\{(?:[^{}\\\\]|\\\\.|\\{[^{}]*\\})*\\}|<[^<>\\n]*>|\\|[^|\\n]*\\|)",
                .string
            ),
            declaration(
                after: ["class", "struct", "module", "enum", "lib", "annotation", "union", "alias", "type", "<"],
                name: "[A-Z]\\w*(?:\\([A-Z]\\w*(?:,[ \\t]*[A-Z]\\w*)*\\))?"),
            declaration(
                after: ["def", "macro", "fun"],
                name: "(?:self\\.|[A-Z]\\w*\\.)?(?:[A-Za-z_]\\w*[?!=]?|\\[\\][?=]?|<=>|===?|=~|!=|<<|>>|<=|>=|\\*\\*|[-+*/%~<>!&|^])",
                .function),
            keywords([
                "abstract", "alias", "alignof", "annotation", "as", "asm", "begin", "break", "case", "class", "def", "do", "else",
                "elsif", "end", "ensure", "enum", "extend", "for", "forall", "fun", "if", "in", "include", "instance_alignof",
                "instance_sizeof", "lib", "macro", "module", "next", "of", "offsetof", "out", "pointerof", "previous_def",
                "private", "protected", "require", "rescue", "return", "select", "self", "sizeof", "struct", "super", "then",
                "type", "typeof", "uninitialized", "union", "unless", "until", "verbatim", "when", "while", "with", "yield",
            ]),
            ("\\.(?:is_a\\?|as\\?|as\\b|responds_to\\?|nil\\?)", .keyword),
            constants(["true", "false", "nil"]),
            ("(?<![:\\w]):[A-Za-z_]\\w*[?!]?", .string),
            ("@{1,2}[A-Za-z_]\\w*", .type),
            decimal,
        ]

    /// The code part of a `#{ … }` or macro `{{ … }}` hole in a Crystal string, which may hold quoted strings and
    /// one more level of braces (`#{"a #{b}"}`, `#{ {{expr}} }`). The `#` that opens a hole stays with the string:
    /// a `#` in code opens a comment, which would otherwise swallow the hole and the rest of the line.
    static let crystalHole: String = {
        let body = "(?:[^{}\"\\n]|\"(?:[^\"\\\\\\n]|\\\\.){0,30}\"|\\{(?:[^{}\\n]|\\{[^{}\\n]{0,30}\\}){0,30}\\}){0,60}"
        return "(?:(?<=(?:^|[^\\\\])#)\\{\(body)\\}|\\{\\{\(body)\\}\\})"
    }()
}

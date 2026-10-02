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

/// Crystal: `"…"` whose `#{ … }` may hold quotes and braces of its own, `<<-HEREDOC` bodies, `%(…)`
/// `%q[…]` `%w{…}` `%i<…>` `%r|…|` percent literals, `/regex/flags`, `` `command` ``, `'c'` chars,
/// `:symbols`, and the language's keywords (`.is_a?`, `.as?` and `.responds_to?` with their dot).
extension RuleTables {
    static let crystal: [(String, TokenKind)] = [
        crystalDoubleQuoted,
        ("'(?:\\\\[^'\\n]+|[^'\\\\\\n])'", .string),
        backQuoted,
        ("<<-(['\"]?)([A-Za-z_]\\w*)\\1[^\\n]*\\n[\\s\\S]*?^[ \\t]*\\2\\b", .string),
        (
            "%[qQwWiIrxs]?(?:\\((?:[^()\\\\]|\\\\.|\\([^()]*\\))*\\)|\\[(?:[^\\[\\]\\\\]|\\\\.|\\[[^\\[\\]]*\\])*\\]|\\{(?:[^{}\\\\]|\\\\.|\\{[^{}]*\\})*\\}|<[^<>\\n]*>|\\|[^|\\n]*\\|)",
            .string
        ),
        ("(?<![\\w)\\]}.])/(?![\\s/=])(?:[^/\\\\\\n]|\\\\.)+/[imx]*", .string),
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

    /// `"…"` whose `#{ … }` may hold quoted strings and braces of its own, so `"a #{"b #{c}"}"` and
    /// `"#{ {{macro}} }"` are each one string. The groups are atomic, so an unclosed `#{` falls back to `#`.
    static let crystalDoubleQuoted: (String, TokenKind) = {
        let plain = "\"(?:[^\"\\\\]|\\\\[\\s\\S])*\""
        let braces = "\\{(?:[^{}]|\\{[^{}]*\\})*\\}"
        func interpolation(_ quoted: String) -> String { "#\\{(?>[^{}\"]+|\(quoted)|\(braces))*\\}" }
        func quoted(_ interpolation: String) -> String { "\"(?>[^\"\\\\#]+|\\\\[\\s\\S]|\(interpolation)|#)*\"" }
        return (quoted(interpolation(quoted(interpolation(plain)))), .string)
    }()
}

//
//  JustRules.swift
//  CodeHighlighting
//
//  The regex rule table for Just (justfiles).
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Just: `#` comments (a `#!` line too: to Just every `#` line is a comment), `"…"` strings whose
/// `{{ … }}` interpolations may hold quotes of their own, `'…'`, `'''…'''`, `"""…"""` (each may carry an
/// `x` or `f` prefix), `` `…` `` / ```` ```…``` ```` backticks, the justfile keywords (`alias`, `export`,
/// `unexport`, `import`, `mod`, `set`, `if`, `else`), recipe headers (the `@` / `_` prefix and the `*`,
/// `+`, `$` parameter marks as keywords, the name and every dependency after the colon as functions),
/// `[attributes]`, a recipe line's `@` / `-` prefix, and the `{{ … }}` of a recipe body, which reads as a
/// string the way VS Code paints it. The words of a recipe body are the shell's, left plain.
extension RuleTables {
    static let just: [(String, TokenKind)] = [
        hashComment,
        tripleDoubleQuoted,
        tripleSingleQuoted,
        justDoubleQuoted,
        (#"(?:\b[fx])?'[^'\n]*'"#, .string),
        (#"\b[fx](?="|''')"#, .string),
        ("```[\\s\\S]*?```", .string),
        backQuoted,
        // A body's `{{ … }}`: quotes inside it (`{{ "}}" }}`) hold their braces.
        ("\\{\\{(?!\\{)(?:[^\"'}\\n]|\"[^\"\\n]*\"|'[^'\\n]*'|\\}(?!\\}))*\\}\\}", .string),
        // A recipe header: everything after its colon is dependencies, then its name and its marks.
        (#":(?<=^[@_]{0,2}[A-Za-z][\w-]{0,80}[^:\n]{0,200}:)(?!=).*$"#, .function),
        (#"^(?:@_|_@|[@_])?[A-Za-z][\w-]*(?![^\n]*:=)(?=[^:\n]*:)"#, .function),
        (#"^(?:@_|_@|[@_])(?=[A-Za-z][\w-]*(?![^\n]*:=)[^:\n]*:)"#, .keyword),
        (#"[ \t][*+$](?=[A-Za-z_](?![^\n]*:=)[^:\n]*:)(?<=^[@_]{0,2}[A-Za-z][^:\n]{0,200})"#, .keyword),
        ("^\\[[^\\]\\n]*\\]", .attribute),
        (#"^[ \t]+[@-]"#, .keyword),
        keywords(["if", "else"]),
        ("^(?:alias|export|unexport|import\\??|mod\\??|set)(?=[ \\t])", .keyword),
        constants(["true", "false"]),
        ("\\$\\{?[A-Za-z_]\\w*\\}?", .type),
        decimal,
    ]

    /// `"…"` (or `x"…"`, `f"…"`) whose `{{ … }}` interpolations may hold quoted strings and `{ … }` blocks of
    /// their own, so `"{{ if os() == "macos" { "mac" } else { "other" } }}"` is one string.
    static let justDoubleQuoted: (String, TokenKind) = {
        let quoted = "\"(?:[^\"\\\\\\n]|\\\\.)*\"|'[^'\\n]*'"
        let block = "\\{(?:[^{}\"']|\(quoted))*\\}"
        let hole = "\\{\\{(?:[^{}\"']|\(quoted)|\(block))*\\}\\}"
        return ("(?:\\b[fx])?\"(?>[^\"\\\\{]+|\\\\[\\s\\S]|\(hole)|\\{)*\"", .string)
    }()
}

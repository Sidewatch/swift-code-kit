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

/// Just: `#` comments, `"…"` strings whose `{{ … }}` interpolations may hold quotes of their own,
/// `'…'`, `'''…'''`, `"""…"""` and `` `…` `` / ```` ```…``` ```` backticks, the justfile keywords
/// (`alias`, `export`, `unexport`, `import`, `mod`, `set`, `if`, `else`), recipe names, `[attributes]`,
/// and the shell words of recipe bodies.
extension RuleTables {
    static let just: [(String, TokenKind)] = [
        hashComment,
        tripleDoubleQuoted,
        tripleSingleQuoted,
        justDoubleQuoted,
        singleQuotedPlain,
        ("```[\\s\\S]*?```", .string),
        backQuoted,
        ("^[A-Za-z_@][\\w-]*(?=[^:=\\n]*:(?!=))", .function),
        ("^\\[[^\\]\\n]*\\]", .attribute),
        keywords([
            "if", "then", "else", "elif", "fi", "for", "while", "do", "done", "case", "esac", "in", "function", "return",
            "exit", "local", "export", "set", "unset", "source", "echo",
        ]),
        ("^(?:alias|export|unexport|import\\??|mod\\??|set)(?=[ \\t])", .keyword),
        constants(["true", "false"]),
        ("\\$\\{?[A-Za-z_]\\w*\\}?", .type),
        decimal,
    ]

    /// `"…"` whose `{{ … }}` interpolations may hold quoted strings and `{ … }` blocks of their own, so
    /// `"{{ if os() == "macos" { "mac" } else { "other" } }}"` is one string.
    static let justDoubleQuoted: (String, TokenKind) = {
        let quoted = "\"(?:[^\"\\\\\\n]|\\\\.)*\"|'[^'\\n]*'"
        let block = "\\{(?:[^{}\"']|\(quoted))*\\}"
        let hole = "\\{\\{(?:[^{}\"']|\(quoted)|\(block))*\\}\\}"
        return ("\"(?>[^\"\\\\{]+|\\\\[\\s\\S]|\(hole)|\\{)*\"", .string)
    }()
}

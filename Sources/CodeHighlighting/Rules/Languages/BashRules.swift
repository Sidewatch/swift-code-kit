//
//  BashRules.swift
//  CodeHighlighting
//
//  The regex rule table for Bash, POSIX sh and Zsh.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The regex rule table for Bash, POSIX sh and Zsh (Bash's own fallback when its grammar is not
/// loaded). A `#` opens a comment only at the start of a word, so `${file##*/}`, `$#` and `a#b` stay
/// code; heredoc bodies down to their delimiter line, `$'…'` and `"…"` holding a `$( … )` with quotes
/// of its own are each one string. Later rules repaint earlier ones; strings and comments paint last.
extension RuleTables {
    static let bash: [(String, TokenKind)] = [
        shellComment,
        shellDoubleQuoted,
        singleQuotedPlain,
        ("\\$'(?:[^'\\\\]|\\\\[\\s\\S])*'", .string),
        shellHeredoc,
        keywords([
            "if", "then", "else", "elif", "fi", "for", "while", "until", "do", "done", "case", "esac", "in", "select",
            "function", "time", "coproc", "return", "break", "continue", "exit", "local", "export", "source", "alias",
            "read", "set", "unset", "shift", "trap", "repeat", "foreach", "always",
        ]),
        ("\\$\\{?[a-zA-Z_]\\w*\\}?|\\$[0-9@?#$!*-]", .type),
        decimal,
        ("\\b\\d+#[0-9A-Za-z@_]+\\b", .number),
        functions([
            "echo", "cd", "ls", "pwd", "mkdir", "rm", "cp", "mv", "cat", "grep",
            "sed", "awk", "find", "sort", "chmod", "curl", "wget", "git",
        ]),
    ]

    /// `#` to the end of the line, when the `#` starts a word: after a space, `;`, `&` or `|`, or at the
    /// start of a line. Anywhere else (`${#x}`, `${x##*/}`, `$#`, `a#b`, `(#q)`) it is code.
    static let shellComment: (String, TokenKind) = ("(?<![^\\s;&|])#.*$", .comment)

    /// `"…"` whose `$( … )` may hold quoted strings of its own, two levels deep — `"$(echo "$(basename "$PWD")")"`
    /// is one string, not three. The groups are atomic, so an unclosed `$(` falls back to a plain `$`.
    static let shellDoubleQuoted: (String, TokenKind) = {
        let plain = "\"(?:[^\"\\\\]|\\\\[\\s\\S])*\""
        func substitution(_ quoted: String) -> String { "\\$\\((?>[^()\"']+|'[^']*'|\(quoted)|\\([^()]*\\))*\\)" }
        func quoted(_ substitution: String) -> String { "\"(?>[^\"\\\\$]+|\\\\[\\s\\S]|\(substitution)|\\$)*\"" }
        return (quoted(substitution(quoted(substitution(plain)))), .string)
    }()

    /// A heredoc from its `<<WORD` (`<<-`, `<<'WORD'`, `<<"WORD"`, `<<\WORD`) to the line holding only
    /// `WORD`. A herestring's `<<<` is not one.
    static let shellHeredoc: (String, TokenKind) = (
        "(?<!<)<<-?[ \\t]*(?:(['\"])\\\\?([A-Za-z_][\\w-]*)\\1|\\\\?([A-Za-z_][\\w-]*))[^\\n]*\\n[\\s\\S]*?^[ \\t]*(?:\\2|\\3)[ \\t]*$",
        .string
    )
}

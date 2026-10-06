//
//  BatchRules.swift
//  CodeHighlighting
//
//  The regex rule table for Windows Batch (cmd.exe).
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Windows Batch: `::` and `REM` comment lines, `"…"` strings with no escapes (a backslash is a path
/// separator, so `"%DROP%\"` ends at its quote) that stop at the line end, `:labels`, every variable
/// form (`%NAME%`, `%NAME:~0,3%`, `%~dp0`, `%1`, `%%F`, `%%~nxF`, `!NAME!`), and cmd.exe's internal
/// commands and comparison words in any case.
extension RuleTables {
    static let batch: [(String, TokenKind)] = [
        ("^[ \\t]*@?::.*$", .comment),
        ("\"[^\"\\n]*(?:\"|$)", .string),
        // A caret escapes the next character (`^&`, `^"`): it is literal, and a `^"` opens no string.
        ("\\^.", .string),
        // A doubled `%` that opens no FOR variable is an escaped percent sign; between spaces (`set /a 7 %% 5`)
        // it is the modulo operator.
        ("%%(?<![ \\t]%%)(?![~A-Za-z])|%%(?=[ \\t]*$)", .string),
        decimal,
        (
            wordTrie(
                [
                    "if", "else", "for", "in", "do", "goto", "call", "exit", "set", "setlocal", "endlocal", "echo", "not",
                    "exist", "defined", "errorlevel", "cmdextversion", "equ", "neq", "lss", "leq", "gtr", "geq", "shift",
                    "pause", "cls", "title", "cd", "chdir", "pushd", "popd", "start", "break", "color", "copy", "date", "del",
                    "dir", "erase", "md", "mkdir", "mklink", "move", "path", "prompt", "rd", "rmdir", "ren", "rename", "time",
                    "type", "ver", "verify", "vol", "assoc", "ftype", "chcp", "on", "off",
                ],
                .keyword,
                caseInsensitive: true
            ).0 + "(?![\\w-])",
            .keyword
        ),
        ("^[ \\t]*:[A-Za-z_][\\w.-]*", .function),
        ("%%(?:~[a-zA-Z]*)?[a-zA-Z]|%~[a-zA-Z]*(?:\\$\\w+:)?[0-9]|%[0-9*]|%[A-Za-z_][^%\\n]*%|![A-Za-z_][^!\\n]*!", .type),
    ]

    /// `REM` opens a comment only as a command: at the start of a line (after an optional `@`, which stays
    /// code) or after `&` or `(`. `echo rem` and `premium` are not comments.
    static let batchRemComment: (String, TokenKind) = ("(?i)rem\\b(?<=(?:^[ \\t]{0,20}@?|[&(][ \\t]{0,20})rem).*$", .comment)
}

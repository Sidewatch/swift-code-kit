//
//  TclRules.swift
//  CodeHighlighting
//
//  The regex rule table for Tcl.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Tcl: `#` comments where a command starts (the line's start or after `;` — `uplevel #0` is an
/// argument), `"…"` strings (a `[command]` inside one may quote again), the control and definition commands as keywords, the other core commands
/// as built-ins, `$name` / `${name}` / `$ns::name` substitutions, `-options`, and numbers (signed, and
/// `1.4.0` versions whole).
extension RuleTables {
    static let tcl: [(String, TokenKind)] = [
        // A `[command]` inside a string may hold quoted strings of its own, two levels deep: one string.
        (
            "\"(?:[^\"\\\\\\[]|\\\\[\\s\\S]|\\[(?:[^\\[\\]\"]|\"(?:[^\"\\\\\\[]|\\\\.|\\[(?:[^\\[\\]\"]|\"[^\"\\n]*\")*\\])*\"|\\[[^\\[\\]]*\\])*\\]|\\[)*\"",
            .string
        ),
        tclWords(
            [
                "after", "apply", "array", "break", "catch", "continue", "coroutine", "else", "elseif", "error", "eval",
                "expr", "for", "foreach", "global", "if", "lmap", "namespace", "proc", "rename", "return", "set",
                "switch", "tailcall", "then", "throw", "trace", "try", "finally", "on", "trap", "unset", "update",
                "uplevel", "upvar", "variable", "vwait", "while", "yield", "yieldto", "oo::class", "oo::define",
                "oo::object", "method", "constructor", "destructor", "superclass", "unknown",
            ], .keyword),
        tclWords(
            [
                "append", "binary", "cd", "chan", "clock", "close", "concat", "dict", "encoding", "eof", "exec", "exit",
                "fconfigure", "file", "flush", "format", "gets", "glob", "incr", "info", "interp", "join", "lappend",
                "lassign", "lindex", "linsert", "list", "llength", "load", "lrange", "lrepeat", "lreplace", "lreverse",
                "lsearch", "lset", "lsort", "open", "package", "pid", "puts", "pwd", "read", "regexp", "regsub", "scan",
                "seek", "socket", "source", "split", "string", "subst", "tell", "time", "unload", "zlib", "my", "next",
                "self",
            ], .function),
        ("\\$(?:\\{[^}\\n]*\\}|(?:::)?[A-Za-z_]\\w*(?:::\\w+)*)", .variable),
        ("(?<=\\s)-[a-z][\\w-]*", .property),
        constants(["true", "false", "yes", "no", "Inf", "NaN"]),
        (
            "(?<![\\w.$-])-?(?:0[xX][0-9a-fA-F]+|0[oO][0-7]+|0[bB][01]+|\\d+(?:\\.\\d+){2,}|\\d+\\.?\\d*(?:[eE][+-]?\\d+)?|\\.\\d+(?:[eE][+-]?\\d+)?)(?![\\w.])",
            .number
        ),
    ]

    /// `words` as one rule of `kind`, whole command words only: a namespace qualifier (`::list`), a `$`
    /// or a dash next to the word makes it part of another name.
    static func tclWords(_ words: [String], _ kind: TokenKind) -> (String, TokenKind) {
        ("(?<![\\w:$-])" + prefixTree(Set(words)) + "(?![\\w:-])", kind)
    }
}

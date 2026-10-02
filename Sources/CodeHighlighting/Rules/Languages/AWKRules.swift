//
//  AWKRules.swift
//  CodeHighlighting
//
//  The regex rule table for AWK.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// AWK: `#` comments, `"…"` strings (a `'` is no quote in AWK), `/…/` regular expressions where a
/// pattern or an operand starts — so the `#` in `/^#/` opens no comment — the keywords and built-in
/// functions of POSIX awk and gawk, `$1`/`$NF` fields, and numbers.
extension RuleTables {
    static let awk: [(String, TokenKind)] = [
        hashComment,
        doubleQuoted,
        (
            "(?:(?<=^[ \\t]{0,40})|(?<=(?:[~(,!{;]|&&|\\|\\||\\bcase)[ \\t]{0,8}))/(?![/=*])(?:[^/\\\\\\n\\[]|\\\\.|\\[\\^?\\]?(?:[^\\]\\\\\\n]|\\\\.|\\[:[a-z]+:\\])*\\])+/",
            .string
        ),
        callee,
        keywords([
            "BEGIN", "END", "BEGINFILE", "ENDFILE", "function", "func", "if", "else", "while", "for", "do", "break",
            "continue", "next", "nextfile", "exit", "return", "delete", "in", "getline", "print", "printf", "switch",
            "case", "default", "close", "fflush", "system",
        ]),
        functions([
            "length", "substr", "index", "split", "sub", "gsub", "match", "sprintf", "sin", "cos", "atan2", "exp",
            "log", "sqrt", "int", "rand", "srand", "tolower", "toupper", "gensub", "patsplit", "strftime", "systime",
            "mktime", "asort", "asorti", "and", "or", "xor", "compl", "lshift", "rshift", "strtonum", "isarray",
            "typeof",
        ]),
        ("\\$(?:\\d+|NF|[A-Za-z_]\\w*)", .variable),
        decimal,
    ]
}

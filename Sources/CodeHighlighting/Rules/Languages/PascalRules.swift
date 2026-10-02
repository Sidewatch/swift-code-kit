//
//  PascalRules.swift
//  CodeHighlighting
//
//  The regex rule table for Pascal (Free Pascal and Delphi).
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Pascal: `{ }`, `(* *)` and `//` comments (a `{$…}` directive is a comment to the compiler's
/// reader too), `'…'` strings whose quote doubles as its own escape, Delphi's `'''` multi-line
/// strings, `#13` character codes, `$FF` / `&17` / `%1010` numbers, and the reserved words in any
/// case. A `"` delimits nothing, so a double quote inside a string stays part of it.
extension RuleTables {
    static let pascal: [(String, TokenKind)] = [
        ("\\{[\\s\\S]*?\\}", .comment),
        ("\\(\\*[\\s\\S]*?\\*\\)", .comment),
        lineComment,
        // A `'''` that ends its line opens a multi-line string, closed by the next `'''` on a line of its own.
        ("'''[ \\t]*\\n[\\s\\S]*?^[ \\t]*'''(?!')", .string),
        ("'(?:[^'\\n]|'')*'", .string),
        ("#(?:\\$[0-9A-Fa-f]+|\\d+)", .string),
        call,
        (
            "(?i)\\b(absolute|and|array|as|asm|begin|bitpacked|case|class|const|constructor|destructor|dispinterface|div|do|downto|else|end|except|exports|file|finalization|finally|for|function|generic|goto|helper|if|implementation|in|inherited|initialization|inline|interface|is|label|library|mod|not|object|of|on|operator|or|out|packed|procedure|program|property|raise|record|reference|reintroduce|repeat|resourcestring|self|set|shl|shr|specialize|then|threadvar|to|try|type|unit|until|uses|var|while|with|xor|abstract|cdecl|default|deprecated|dynamic|external|forward|message|nested|overload|override|platform|private|protected|public|published|read|register|safecall|sealed|static|stdcall|stored|strict|virtual|write)\\b",
            .keyword
        ),
        (
            "(?i)\\b(boolean|byte|cardinal|char|currency|double|extended|int64|integer|longint|longword|nativeint|pchar|pointer|real|shortint|single|smallint|string|uint64|variant|widechar|word|ansistring|unicodestring|widestring)\\b",
            .type
        ),
        ("\\bT[A-Z]\\w*\\b", .type),
        ("(?i)\\b(true|false|nil)\\b", .number),
        ("\\$[0-9A-Fa-f][0-9A-Fa-f_]*\\b|&[0-7][0-7_]*\\b|%[01][01_]*\\b", .number),
        ("\\b\\d[\\d_]*(?:\\.\\d[\\d_]*)?(?:[eE][+-]?\\d+)?\\b", .number),
    ]
}

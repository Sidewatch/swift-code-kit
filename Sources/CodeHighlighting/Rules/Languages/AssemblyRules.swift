//
//  AssemblyRules.swift
//  CodeHighlighting
//
//  The regex rule table for assembly (NASM / GAS).
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Assembly, NASM and GAS: `;` and `#` comments, labels, directives, the x86 and ARM register
/// names, an indented mnemonic, memory operands (a size keyword inside one stays a keyword), and numbers in
/// every NASM form (`0b1010_0101`, `777o`, `0A5h`, `1.0e10`).
extension RuleTables {
    static let assembly: [(String, TokenKind)] = [
        (";.*$", .comment),
        ("^\\s*#.*$", .comment),
        // `//` opens a GAS comment; followed by a number or a bracket it is NASM's signed division.
        ("//(?![ \\t]*[\\d(]).*$", .comment),
        doubleQuotedPlain,
        singleQuotedPlain,
        ("^\\s*[A-Za-z_.$][\\w.$]*:", .function),
        ("\\[[^\\]]*\\]", .property),
        ("^\\s*\\.[a-z_]+\\b", .keyword),
        (
            "(?i)\\b(section|segment|global|globl|extern|common|static|equ|db|dw|dd|dq|dt|do|dy|dz|resb|resw|resd|resq|rest|reso|resy|resz|times|org|bits|default|align|alignb|use16|use32|use64|struc|endstruc|istruc|iend|at|macro|endmacro|include|incbin|byte|word|dword|qword|tword|oword|yword|zword|ptr|offset|rel|abs|strict|nosplit|seg|wrt|absolute)\\b",
            .keyword
        ),
        (
            "(?i)\\b(r[abcd]x|e[abcd]x|[abcd][lhx]|r[sd]i|e[sd]i|[sd]il?|r[sb]p|e[sb]p|[sb]pl?|r(8|9|1[0-5])[dwb]?|[xyz]mm\\d{1,2}|st\\(?\\d\\)?|[cdefgs]s|rip|eip|eflags|x\\d{1,2}|w\\d{1,2}|sp|lr|pc|fp|xzr|wzr|v\\d{1,2})\\b",
            .variable
        ),
        ("%[a-z]+[0-9a-z]*", .variable),
        ("^\\s+[a-zA-Z][a-zA-Z0-9.]*\\b", .keyword),
        (
            "\\b(?:0[xX][0-9a-fA-F_]+|0[oOqQ][0-7_]+|0[bByY][01_]+|[0-9][0-9a-fA-F_]*[hH]|[0-7][0-7_]*[oOqQ]|[01][01_]*[bByY]|\\d[\\d_]*(?:\\.\\d[\\d_]*)?(?:[eE][-+]?\\d+)?)\\b|\\$[0-9a-fA-Fx]+",
            .number
        ),
    ]
}

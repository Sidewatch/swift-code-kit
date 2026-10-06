//
//  VHDLRules.swift
//  CodeHighlighting
//
//  The regex rule table for VHDL.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// VHDL: the IEEE 1076-2019 reserved words in any case, `"…"` strings with `""` escapes, `'c'`
/// character literals (an attribute tick such as `clk'event` is not one), bit strings (`X"FF"`,
/// `12SX"7FF"`) and based literals (`16#FF#`) as numbers, the standard types, and the name an `entity`,
/// `architecture … of`, `component`, `configuration` or `package` declares (or an `end` repeats) as a type.
extension RuleTables {
    static let vhdl: [(String, TokenKind)] = [
        // A string's quote never follows a letter or digit: that `"` closes a bit string (`X"FF"`).
        ("(?<![A-Za-z0-9\"])\"(?:[^\"\\n]|\"\")*\"", .string),
        ("(?<![\\w)\\]])'.'", .string),
        // The name a design unit or record declares, or its `end` repeats, is a type; the keywords repaint below.
        (
            "(?i)\\b(?:entity|architecture|component|configuration|package(?:[ \\t]+body)?|end[ \\t]+(?:entity|architecture|component|configuration|package|record|units))[ \\t]+[a-z]\\w*(?:[ \\t]+of[ \\t]+[a-z]\\w*)?",
            .type
        ),
        wordTrie(vhdlReservedWords, .keyword, caseInsensitive: true),
        (
            "(?i)\\b(std_u?logic(?:_vector)?|u?x01z?|integer|natural|positive|boolean|bit(?:_vector)?|real|time|delay_length|string|character|severity_level|file_open_kind|line|text|(?:un)?signed|sfixed|ufixed|float(?:32|64|128)?|boolean_vector|integer_vector|real_vector|time_vector)\\b",
            .type
        ),
        ("(?i)\\b(true|false)\\b", .number),
        ("\\b\\d+#[0-9A-Fa-f_.]+#(?:[eE][+-]?\\d+)?", .number),
        decimal,
        ("(?i)\\b\\d*[us]?[boxd]\"[^\"\\n]*\"", .number),
    ]

    /// The reserved words of IEEE 1076-2019.
    static let vhdlReservedWords = [
        "abs", "access", "after", "alias", "all", "and", "architecture", "array", "assert", "assume", "attribute", "begin",
        "block", "body", "buffer", "bus", "case", "component", "configuration", "constant", "context", "cover", "default",
        "disconnect", "downto", "else", "elsif", "end", "entity", "exit", "fairness", "file", "for", "force", "function",
        "generate", "generic", "group", "guarded", "if", "impure", "in", "inertial", "inout", "is", "label", "library",
        "linkage", "literal", "loop", "map", "mod", "nand", "new", "next", "nor", "not", "null", "of", "on", "open", "or",
        "others", "out", "package", "parameter", "port", "postponed", "private", "procedure", "process", "property",
        "protected", "pure", "range", "record", "register", "reject", "release", "rem", "report", "restrict", "return",
        "rol", "ror", "select", "sequence", "severity", "shared", "signal", "sla", "sll", "sra", "srl", "strong",
        "subtype", "then", "to", "transport", "type", "unaffected", "units", "until", "use", "variable", "view", "vmode",
        "vpkg", "vprop", "vunit", "wait", "when", "while", "with", "xnor", "xor",
    ]
}

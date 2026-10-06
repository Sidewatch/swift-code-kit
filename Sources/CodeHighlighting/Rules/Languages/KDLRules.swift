//
//  KDLRules.swift
//  CodeHighlighting
//
//  The regex rule table for KDL.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// KDL: `//`, nestable `/* */`, and `/-` slashdash — which comments out a whole node (to its line's end, with its
/// `{ children }`), a children block, or one argument or property — `"…"` and `"""…"""` strings, raw `#"…"#`
/// strings of any hash count, bare identifier-string arguments after a node name, `#true`/`#null`/`#inf`
/// keywords, `(type)` annotations, `key=` properties, numbers.
extension RuleTables {
    static let kdl: [(String, TokenKind)] = [
        lineComment,
        ("(?<=^[ \\t]{0,40})/-[^\\n{]*(?:\\{(?:[^{}]|\\{(?:[^{}]|\\{[^{}]*\\})*\\})*\\}[^\\n]*)?", .comment),
        ("/-[ \\t]*\\{(?:[^{}]|\\{(?:[^{}]|\\{[^{}]*\\})*\\})*\\}", .comment),
        ("/-[ \\t]*(?:\"(?:[^\"\\\\]|\\\\.)*\"|[^\\s;{}]+)", .comment),
        ("/\\*(?:[^*/]|\\*(?!/)|/(?!\\*)|/\\*(?:[^*]|\\*(?!/))*\\*/)*\\*/", .comment),
        ("(#+)\"\"\"[\\s\\S]*?\"\"\"\\1", .string),
        ("(#+)\"[^\\n]*?\"\\1", .string),
        ("\"\"\"(?:[^\"\\\\]|\\\\[\\s\\S]|\"(?!\"\"))*\"\"\"", .string),
        doubleQuoted,
        ("(?<=[^\\s{;])[ \\t]+(?![#\"/(]|[+-]?\\.?\\d)[^\\s=;{}()\\\\/\"#\\[\\]]+(?=[ \\t;}]|$)", .string),
        ("#(?:true|false|null|nan|inf|-inf)\\b", .keyword),
        ("\\([A-Za-z_][\\w-]*\\)", .type),
        ("[^\\s=;{}()\"\\\\]+(?==)", .property),
        (
            "(?<![\\w.-])[+-]?(?:0x[0-9a-fA-F_]+|0o[0-7_]+|0b[01_]+|\\d[\\d_]*(?:\\.\\d[\\d_]*)?(?:[eE][+-]?\\d[\\d_]*)?)(?![\\w.-])",
            .number
        ),
    ]
}

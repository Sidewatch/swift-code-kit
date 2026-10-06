//
//  PRQLRules.swift
//  CodeHighlighting
//
//  The regex rule table for PRQL.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// PRQL: `#` comments, `"…"` and `'…'` strings with escapes and their `"""…"""` / `'''…'''` forms,
/// each with an optional `r`, `f` or `s` prefix (an f-string's or s-string's `{expr}` holes stay code), the
/// keywords and pipeline transforms, the standard library's functions and types, the name a `module` declares,
/// `<type>` annotations, `@dates`, and numbers with their duration units (`3months`, `100milliseconds`).
/// Without it PRQL fell to the SQL family, which knows neither `#` comments nor `"…"` strings.
extension RuleTables {
    static let prql: [(String, TokenKind)] =
        [
            hashComment,
            ("(?:\\b[rfs])?\"\"\"[\\s\\S]*?\"\"\"", .string),
            ("(?:\\b[rfs])?'''[\\s\\S]*?'''", .string),
            // A quote right after a `}` closes an f-string or s-string and opens nothing.
            ("(?:\\br)?\"(?<!\\}\")(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
            ("(?:\\b[rfs])?'(?:[^'\\\\\\n]|\\\\.)*'", .string),
        ]
        // An f-string's or s-string's `{expr}` holes stay code; `{{` and `}}` are braces of its text.
        + interpolatedStringPieces(
            open: "\\b[fs]\"", close: "\"", literal: "[^\"\\\\{}\\n]|\\\\.|\\{\\{|\\}\\}", hole: "\\{(?!\\{)[^{}\"\\n]*\\}",
            holeOpen: "\\{(?!\\{)", holeClose: "\\}",
            skip: [
                "#[^\\n]*", "(?:\\b[rfs])?\"\"\"[\\s\\S]*?\"\"\"", "(?:\\b[rfs])?'''[\\s\\S]*?'''", "(?:\\br)?\"(?:[^\"\\\\\\n]|\\\\.)*\"",
                "(?:\\b[rfs])?'(?:[^'\\\\\\n]|\\\\.)*'",
            ])
        + [
            call,
            ("\\bmodule[ \\t]+[A-Za-z_]\\w*", .type),  // the module a `module` block declares
            keywords([
                "let", "into", "case", "prql", "type", "module", "internal", "func", "from", "select", "derive", "filter",
                "take", "sort", "join", "group", "aggregate", "window", "append", "loop", "side", "rows",
                "range", "expanding", "rolling",
            ]),
            // The standard library's functions, called without parentheses (`sum revenue`, `text.lower name`).
            wordTrie(
                [
                    "min", "max", "sum", "average", "stddev", "every", "any", "concat_array", "count", "lag", "lead", "first",
                    "last", "rank", "rank_dense", "row_number", "round", "in", "tuple_every", "tuple_map", "tuple_zip",
                    "from_text", "lower", "upper", "read_parquet", "read_csv",
                ], .function),
            types(["bool", "int", "int8", "int16", "int32", "int64", "int128", "float", "text"]),
            ("(?<=<)[ \\t]*[a-z]+(?:[ \\t]*\\|\\|[ \\t]*[a-z]+)*[ \\t]*(?=>)", .type),
            constants(["true", "false", "null"]),
            decimal,
            ("\\b\\d+(?:years|months|weeks|days|hours|minutes|seconds|milliseconds|microseconds)\\b", .number),
            ("@\\d[\\d:T.+-]*Z?", .number),
        ]
}

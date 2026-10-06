//
//  CapnpRules.swift
//  CodeHighlighting
//
//  The regex rule table for Cap'n Proto schemas.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Cap'n Proto: `#` comments (the language table adds them); `"…"` text and `0x"…"` data literals — there
/// are no `'…'` strings; `@0x…` file and type IDs and `@N` ordinals; `$annotations`; the schema keywords and
/// built-in types; and every capitalised name as a type, the schema's convention (`:Point`, `List(Text)`,
/// `struct Wrapper(T)`): a schema has no calls, so a name before `(` is a generic type.
extension RuleTables {
    static let capnp: [(String, TokenKind)] = [
        ("(?:\\b0x)?\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
        ("\\b[A-Z]\\w*", .type),
        keywords([
            "annotation", "const", "enum", "extends", "group", "import", "interface", "struct", "union", "using",
            "embed", "stream",
        ]),
        types([
            "Void", "Bool", "Int8", "Int16", "Int32", "Int64", "UInt8", "UInt16", "UInt32", "UInt64", "Float32",
            "Float64", "Text", "Data", "List", "AnyPointer", "AnyStruct", "AnyList", "Capability",
        ]),
        constants(["true", "false", "void", "inf", "nan"]),
        ("\\$[A-Za-z_][\\w.]*", .attribute),
        ("@0x[0-9a-fA-F]+|@\\d+", .number),
        decimal,
    ]
}

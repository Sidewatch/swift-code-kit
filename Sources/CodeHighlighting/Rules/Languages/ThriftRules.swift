//
//  ThriftRules.swift
//  CodeHighlighting
//
//  The regex rule table for Thrift.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Thrift IDL: `//`, `#` and `/* */` comments (the language table adds them); `"…"` and `'…'` literals; the
/// IDL's keywords, field requiredness and base types; field ids (`1:`); numbers, a negative one with its
/// sign (the IDL has no subtraction); the type a `struct`, `union`, `exception`, `enum`, `senum` or
/// `service` declares or `extends` names; a service method's name (`getOrder(` — a name before ` (` with a
/// space is a field followed by its annotations).
extension RuleTables {
    static let thrift: [(String, TokenKind)] = [
        doubleQuoted,
        singleQuoted,
        declaration(
            after: ["struct", "union", "exception", "enum", "senum", "service", "extends"], name: "[A-Za-z_][\\w.]*"),
        ("\\b[A-Za-z_]\\w*(?=\\()", .function),
        keywords([
            "async", "const", "cpp_include", "cpp_namespace", "cpp_type", "enum", "exception", "extends", "include",
            "namespace", "oneway", "optional", "php_namespace", "py_module", "required", "senum", "service", "struct",
            "throws", "typedef", "union", "xsd_all", "xsd_attrs", "xsd_namespace", "xsd_nillable", "xsd_optional",
        ]),
        types([
            "binary", "bool", "byte", "double", "i8", "i16", "i32", "i64", "list", "map", "set", "slist", "string",
            "uuid", "void",
        ]),
        constants(["true", "false"]),
        ("\\B-\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?\\b", .number),
        decimal,
    ]
}

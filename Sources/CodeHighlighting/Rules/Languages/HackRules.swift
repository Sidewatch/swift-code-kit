//
//  HackRules.swift
//  CodeHighlighting
//
//  The regex rule table for Hack.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Hack: `//`, `#` and `/* */` comments, `<!-- -->` inside XHP; `'…'` and `"…"` strings with backslash
/// escapes; heredocs and nowdocs (`<<<EOT`, `<<<"EOT"`, `<<<'EOT'`) up to their closing label, which may
/// be indented; `$variables`; `<<__Attributes>>`; the language's own keywords and built-in types.
extension RuleTables {
    static let hack: [(String, TokenKind)] = [
        hashComment,
        htmlComment,
        ("<<<[ \\t]*([\"']?)([A-Za-z_]\\w*)\\1[ \\t]*\\n[\\s\\S]*?^[ \\t]*\\2\\b", .string),
        doubleQuoted,
        singleQuoted,
        callee,
        wordTrie(
            [
                "abstract", "as", "async", "attribute", "await", "break", "case", "catch", "category", "children", "class",
                "clone", "concurrent", "const", "continue", "ctx", "default", "do", "echo", "else", "elseif", "enum",
                "exit", "extends", "final", "finally", "for", "foreach", "from", "function", "if", "implements", "include",
                "include_once", "inout", "instanceof", "insteadof", "interface", "internal", "is", "isset", "list",
                "module", "namespace", "nameof", "new", "newtype", "parent", "print", "private", "protected", "public",
                "readonly", "reify", "require", "require_once", "return", "self", "shape", "static", "super", "switch",
                "throw", "trait", "try", "tuple", "type", "unset", "upcast", "use", "using", "where", "while", "xhp",
                "yield", "this",
            ], .keyword),
        wordTrie(
            [
                "arraykey", "bool", "classname", "darray", "dict", "dynamic", "float", "int", "keyset", "mixed", "nonnull",
                "noreturn", "nothing", "null", "num", "resource", "string", "varray", "vec", "vec_or_dict", "void",
            ], .type),
        constants(["true", "false", "null", "TRUE", "FALSE", "NULL"]),
        ("<<\\w[\\w\\s,()':\\\\]*>>", .attribute),
        ("\\$[a-zA-Z_]\\w*", .property),
        ("\\b__[A-Z]+__\\b", .number),
        decimal,
    ]
}

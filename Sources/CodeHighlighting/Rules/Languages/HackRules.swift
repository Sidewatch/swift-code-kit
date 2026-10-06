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

/// Hack: `//` and `/* */` comments (`#` is not a comment in Hack: its lexer reads a `#` as a token),
/// `<!-- -->` inside XHP; `'…'` and `"…"` strings with backslash escapes; heredoc and nowdoc bodies
/// (`<<<EOT`, `<<<"EOT"`, `<<<'EOT'`) up to the closing label, which ends the literal only at the start
/// of a line followed by `;` or the line break (HHVM's own rule), the labels themselves left code;
/// `$variables`; `<<__Attributes>>`; the names declared by `class`, `interface`, `trait`, `enum`,
/// `type`, `newtype`, `namespace` and `module`, the classes after `extends` / `implements`, and the
/// namespace prefixes of a qualified name (`HH\Lib\C\`) as types; a declared function's name; the
/// language's own keywords and built-in types.
extension RuleTables {
    static let hack: [(String, TokenKind)] = [
        htmlComment,
        ("\\n(?<=<<<[ \\t]{0,8}[\"']?([A-Za-z_]\\w{0,63})[\"']?[ \\t]{0,8}\\n)[\\s\\S]*?(?:(?=\\n\\1;?$)|\\z)", .string),
        ("<<<[ \\t]*[\"']?(?=[A-Za-z_])", .string),
        ("[\"'](?<=<<<[ \\t]{0,8}[\"'][A-Za-z_]\\w{0,63}[\"'])", .string),
        ("\"(?<!<<<\")(?<!<<<\"[A-Za-z_]\\w{0,63}\")(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
        ("'(?<!<<<')(?<!<<<'[A-Za-z_]\\w{0,63}')(?:[^'\\\\]|\\\\[\\s\\S])*'", .string),
        ("\\b[A-Za-z_]\\w*\\\\", .type),
        declaration(
            after: [
                "enum[ \\t]+class", "class", "interface", "trait", "enum", "newtype", "type", "namespace", "module", "extends",
                "implements",
            ],
            name: "[A-Za-z_][\\w\\\\]*"),
        declaration(after: ["function"], .function),
        callee,
        wordTrie(
            [
                "abstract", "as", "async", "attribute", "await", "break", "case", "catch", "category", "children", "class",
                "clone", "concurrent", "const", "continue", "ctx", "default", "do", "echo", "else", "enum",
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

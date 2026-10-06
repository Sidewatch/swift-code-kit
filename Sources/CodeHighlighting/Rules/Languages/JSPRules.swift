//
//  JSPRules.swift
//  CodeHighlighting
//
//  The regex rule table for JSP (Jakarta Server Pages).
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// JSP: `<%-- --%>` comments (the language's own), the `<% %>` / `<%= %>` / `<%! %>` / `<%@ %>`
/// delimiters and the Java inside them (`//` and `/* */` comments, strings and text blocks, keywords,
/// types, numbers), Expression Language in `${ }` / `#{ }`, and the XML-style tags around them, whose
/// attribute values are strings (an expression or an action inside one included, a scriptlet not).
extension RuleTables {
    static let jsp: [(String, TokenKind)] =
        [
            htmlComment,
            (insideScriptletTag + "//(?:(?!%>)[^\\n])*", .comment),
            (insideScriptletTag + "/\\*[\\s\\S]*?\\*/", .comment),
            (insideScriptletTag + "\"\"\"[\\s\\S]*?\"\"\"", .string),
        ] + tagStrings(insideJSPCode) + [
            // An attribute value is a string whole, an expression or an action inside it included; one
            // that holds a scriptlet (`value="<%= year %>"`) keeps only its quotes in the string colour.
            ("(?<==)\"(?:[^\"\\n<]|<(?!%))*\"", .string),
            ("(?<==)'(?:[^'\\n<]|<(?!%))*'", .string),
            ("(?<==)[\"'](?=[^\"'\\n]*<%)|[\"'](?<=%>[\"'])", .string),
            ("</?[A-Za-z][\\w:.-]*|/>|>", .keyword),
            ("\\b[A-Za-z-]+=", .property),
            ("<%[!=@]?|%>|[$#]\\{", .keyword),
            ("(?<=<%@)\\s*[a-z]+", .keyword),
            (insideJSPCode + "\\b([a-zA-Z_]\\w*)(?=\\s*\\()", .function),
            tagWords(
                [
                    "abstract", "break", "case", "catch", "class", "continue", "default", "do", "else", "enum", "extends", "final",
                    "finally", "for", "if", "implements", "import", "instanceof", "interface", "new", "private", "protected", "public",
                    "return", "static", "super", "switch", "this", "throw", "throws", "try", "var", "while", "empty", "not", "and", "or",
                    "eq", "ne", "lt", "gt", "le", "ge", "div", "mod",
                ], .keyword, insideJSPCode),
            tagWords(
                [
                    "boolean", "byte", "char", "double", "float", "int", "long", "short", "void", "String", "Integer", "Object", "List",
                    "Map",
                ],
                .type, insideJSPCode),
            tagWords(["true", "false", "null"], .number, insideJSPCode),
            (insideJSPCode + "\\b(?:0[xX][0-9a-fA-F]+|\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?)\\b", .number),
        ]

    /// Inside a scriptlet (`<% … %>`, which holds Java's own braces) or an EL expression (`${ … }`).
    static let insideJSPCode = insideScriptletTag + inside(opens: ["[$#]\\{"], closes: ["\\}"])
}

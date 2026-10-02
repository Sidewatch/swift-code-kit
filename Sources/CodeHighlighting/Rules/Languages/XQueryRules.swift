//
//  XQueryRules.swift
//  CodeHighlighting
//
//  The regex rule table for XQuery.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// XQuery: nesting `(: … :)` comments, `<!-- -->` and CDATA in constructors, `$variables`, the FLWOR
/// and declaration words, prefixed names (`xs:decimal`, `fn:count`), embedded element constructors, `@attributes`.
extension RuleTables {
    static let xquery: [(String, TokenKind)] = [
        nestedBlock("(:", ":)"),  // `(: … (: nested :) … :)` is one comment
        htmlComment,
        ("<!\\[CDATA\\[[\\s\\S]*?\\]\\]>", .string),
        doubleQuotedPlain,
        singleQuotedPlain,
        keywords([
            "xquery", "version", "encoding", "declare", "namespace", "default", "element", "attribute", "function", "variable", "option",
            "boundary-space", "base-uri", "construction", "ordering", "copy-namespaces", "module", "import", "schema", "at", "external",
            "let", "for", "in", "where", "order", "by", "stable", "return", "if", "then", "else", "as", "every", "some", "satisfies",
            "typeswitch", "case", "ascending", "descending", "empty", "greatest", "least", "collation", "instance", "of", "treat",
            "castable", "cast", "to", "div", "idiv", "mod", "and", "or", "not", "eq", "ne", "lt", "le", "gt", "ge", "is", "union",
            "intersect", "except", "child", "descendant", "parent", "self", "ancestor", "text", "node", "document-node", "item", "count",
            "group", "window", "tumbling", "sliding", "try", "catch", "switch",
        ]),
        ("\\b(xs|fn|math|map|array|local|ex):[\\w-]+", .type),
        ("</?[A-Za-z][\\w:-]*|/>|>", .keyword),
        ("@[\\w:-]+", .attribute),
        // A call, but never `if (`, `in (` or another keyword before a parenthesis.
        (
            "\\b(?!(?:if|in|return|typeswitch|switch|some|every|for|let|where|then|else|and|or|empty|as|of)\\b)[A-Za-z_][\\w-]*(?=[ \\t]*\\()",
            .function
        ),
        ("\\b\\d+(\\.\\d+)?([eE][+-]?\\d+)?\\b", .number),
        ("\\$[\\w:.-]+", .variable),  // last, so `$sliding` and `$x` are never a keyword or a call
    ]
}

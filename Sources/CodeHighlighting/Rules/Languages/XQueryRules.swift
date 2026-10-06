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

/// XQuery: nesting `(: … :)` comments, `<!-- -->` and CDATA in constructors, string constructors, `$variables`,
/// the FLWOR, window, update and declaration words, kind tests in a type as keywords, axes, prefixed names
/// (`xs:decimal`, `fn:count`) as types and as calls, named function references (`ex:money#1`), embedded element
/// constructors, `@attributes`.
extension RuleTables {
    static let xquery: [(String, TokenKind)] = [
        nestedBlock("(:", ":)"),  // `(: … (: nested :) … :)` is one comment
        htmlComment,
        ("<!\\[CDATA\\[[\\s\\S]*?\\]\\]>", .string),
        ("``\\[[\\s\\S]*?\\]``", .string),  // a string constructor, ``[ … ]``
        doubleQuotedPlain,
        singleQuotedPlain,
        wordTrie(
            [
                "xquery", "version", "encoding", "declare", "namespace", "default", "element", "attribute", "function", "variable",
                "option",
                "boundary-space", "base-uri", "construction", "ordering", "copy-namespaces", "module", "import", "schema", "at", "external",
                "let", "for", "in", "where", "order", "by", "stable", "return", "if", "then", "else", "as", "every", "some", "satisfies",
                "typeswitch", "case", "ascending", "descending", "empty", "greatest", "least", "collation", "instance", "of", "treat",
                "castable", "cast", "to", "div", "idiv", "mod", "and", "or", "not", "eq", "ne", "lt", "le", "gt", "ge", "is", "union",
                "intersect", "except", "child", "descendant", "parent", "self", "ancestor", "text", "node", "document-node", "item",
                "count",
                "group", "window", "tumbling", "sliding", "try", "catch", "switch", "context", "strip", "preserve", "no-preserve",
                "inherit", "no-inherit", "ordered", "unordered", "strict", "lax", "start", "end", "when", "only", "previous", "next",
                "allowing", "map", "array", "comment", "processing-instruction", "namespace-node", "schema-element",
                "schema-attribute", "empty-sequence", "document", "validate", "copy", "modify", "insert", "delete", "replace",
                "rename", "transform", "updating", "nodes", "into", "first", "last", "before", "after", "with", "value",
            ], .keyword),
        ("\\b(xs|fn|math|map|array|local|ex):[\\w-]+", .type),
        ("</?[A-Za-z][\\w:-]*|/>|>", .keyword),
        ("@[\\w:-]+", .attribute),
        // A call, prefixed or not, but never `if (` or another keyword before a parenthesis.
        (
            "\\b(?!(?:if|in|return|typeswitch|switch|some|every|for|let|where|then|else|and|or|empty|as|of|union|intersect|except|map|array)(?![\\w:-]))(?:[A-Za-z_][\\w-]*:)?[A-Za-z_][\\w-]*(?=[ \\t]*\\()",
            .function
        ),
        // A kind test in a type (`as item()*`, `as function(*)`) is a keyword; in a path step (`$o/node()`)
        // it stays a call.
        (
            "\\bas[ \\t]+(?:item|node|text|comment|element|attribute|document-node|processing-instruction|namespace-node|schema-element|schema-attribute|empty-sequence|function|map|array)(?![\\w:-])",
            .keyword
        ),
        ("\\b(?:[A-Za-z_][\\w-]*+:)?+[A-Za-z_][\\w-]*+(?=#\\d)", .function),  // a named function reference, `ex:money#1`
        ("#(?=\\d)", .keyword),
        (
            "\\b(?:ancestor-or-self|ancestor|attribute|child|descendant-or-self|descendant|following-sibling|following|namespace|parent|preceding-sibling|preceding|self)(?=::)",
            .keyword
        ),
        ("\\b\\d+(\\.\\d+)?([eE][+-]?\\d+)?\\b", .number),
        ("\\$[\\w:.-]+", .variable),  // last, so `$sliding` and `$x` are never a keyword or a call
    ]
}

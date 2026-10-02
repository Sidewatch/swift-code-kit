//
//  DotRules.swift
//  CodeHighlighting
//
//  The regex rule table for Graphviz DOT.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Graphviz DOT: `//`, `/* */` and `#` comments, the graph words, `->` / `--` edges,
/// `attr=value` pairs (an unquoted value is a string like a quoted one), quoted labels, numbers.
extension RuleTables {
    static let dot: [(String, TokenKind)] = [
        lineComment,
        blockComment,
        ("^\\s*#.*$", .comment),
        doubleQuoted,
        ("<[^>]*>", .string),
        ("->|--", .type),
        ("\\b[A-Za-z_][\\w]*(?=\\s*=)", .attribute),
        (
            "\\b(rankdir|label|shape|style|color|fillcolor|fontname|fontsize|penwidth|arrowhead|dir|weight|constraint|splines|nodesep|ranksep|bgcolor|layout|compound|width|height)\\b",
            .attribute
        ),
        ("#[0-9A-Fa-f]{6}\\b|(?<![\\w.])-?(?:\\d+(?:\\.\\d*)?|\\.\\d+)\\b", .number),
        ("\\b[A-Za-z_]\\w*(?=\\s*(\\[|->|--|;|$))", .variable),
        // The graph words are case-independent (`NODE`, `SubGraph`) and win over the node-name rule above.
        ("(?i)\\b(digraph|graph|subgraph|node|edge|strict)\\b", .keyword),
        // An unquoted attribute value (`shape = box`, `compound = true`) is a value like a quoted one.
        ("(?<==[ \\t]{0,8})[A-Za-z_][\\w.]*", .string),
    ]
}

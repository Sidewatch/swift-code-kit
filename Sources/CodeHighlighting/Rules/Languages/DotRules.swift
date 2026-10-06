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

/// Graphviz DOT: `//`, `/* */` and `#` comments, the graph words, `->` / `--` edges, `attr=value`
/// pairs (an unquoted value is a string like a quoted one, and `+` joins quoted values), node and
/// graph IDs (quoted or not) as names, HTML-like labels' tags and attribute values, numbers.
extension RuleTables {
    static let dot: [(String, TokenKind)] = [
        lineComment,
        blockComment,
        ("^\\s*#.*$", .comment),
        // A quoted value after `=` or a joining `+` is a string; a quoted ID anywhere else is a name (the
        // last rule, so no word inside it is painted).
        ("\"(?<=[=+][ \\t]{0,8}\")(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
        // An HTML-like label (`label = <<B>bold</B>>`): its tags.
        ("</?[A-Za-z][\\w]*|/?>", .keyword),
        ("->|--", .type),
        ("\\b[A-Za-z_][\\w]*(?=\\s*=)", .property),
        (
            "\\b(rankdir|label|shape|style|color|fillcolor|fontname|fontsize|penwidth|arrowhead|dir|weight|constraint|splines|nodesep|ranksep|bgcolor|layout|compound|width|height)\\b",
            .property
        ),
        ("#[0-9A-Fa-f]{6}\\b|(?<![\\w.])-?(?:\\d+(?:\\.\\d*)?|\\.\\d+)(?!\\w)", .number),
        ("\\b[A-Za-z_]\\w*(?=\\s*(\\[|->|--|;|$))", .variable),
        // The graph words are case-independent (`NODE`, `SubGraph`) and win over the node-name rule above.
        ("(?i)\\b(digraph|graph|subgraph|node|edge|strict)\\b", .keyword),
        // An unquoted attribute value (`shape = box`, `compound = true`) is a value like a quoted one.
        ("(?<==[ \\t]{0,8})[A-Za-z_][\\w.]*", .string),
        ("\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .variable),
    ]
}

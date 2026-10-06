//
//  MermaidRules.swift
//  CodeHighlighting
//
//  The regex rule table for Mermaid.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Mermaid: `%%` comments, the diagram and structure words (`quadrant-1` …), arrows, node shapes —
/// their brackets keywords, their label a string — link labels between `|` bars, quoted text, `[*]`
/// states, a message's text after `: `, node names at a line's start, numbers.
extension RuleTables {
    static let mermaid: [(String, TokenKind)] = [
        ("%%.*$", .comment),
        ("\"[^\"\\n]*\"", .string),
        // A node name at a line's start; the words below repaint the structure words among them.
        ("^\\s*[A-Za-z_][\\w-]*", .variable),
        (
            "\\b(?:graph|flowchart|sequenceDiagram|classDiagram|stateDiagram(?:-v2)?|erDiagram|gantt|pie|journey|gitGraph|mindmap|timeline|quadrantChart|requirementDiagram|C4Context|C4Container|C4Component|C4Dynamic|C4Deployment|sankey-beta|xychart-beta|block-beta|packet-beta|kanban|architecture-beta|radar-beta|treemap-beta)\\b",
            .keyword
        ),
        keywords([
            "subgraph", "end", "direction", "title", "note", "Note", "right", "left", "of", "over", "participant", "actor",
            "activate", "deactivate", "loop", "alt", "else", "opt", "par", "and", "critical", "break", "option", "rect", "box",
            "autonumber", "section", "class", "state", "click", "style", "classDef", "linkStyle", "dateFormat", "axisFormat",
            "excludes", "todayMarker", "as", "TB", "TD", "BT", "RL", "LR", "commit", "branch", "checkout", "merge",
            "cherry-pick", "namespace", "accTitle", "accDescr", "showData", "fork", "join", "choice", "x-axis", "y-axis",
            "requirement", "element", "satisfies", "verifymethod", "risk",
        ]),
        ("\\bquadrant-[1-4]\\b", .keyword),
        ("\\[\\*\\]", .keyword),
        ("<?-{1,3}>?|<?={1,3}>?|-\\.+->|--\\|>|\\.\\.>|\\*--|o--|<\\|--|--\\*|--o|-->>|--x|--\\)|:::|-\\.-", .type),
        // A node shape's brackets (`[ ]`, `( )`, `{ }`, `[[ ]]`, `[( )]`, `[/ /]`, `>` …) and a link label's bars.
        ("[\\[\\](){}|]|(?<=\\w)>(?=[^\\s>-])", .keyword),
        // The label inside a node shape or between a link's bars; a message's text after `: `.
        ("(?<=[\\[({|/\\\\]|\\w>)(?![\\[({/\\\\\\s])[^\\[\\](){}|\\n\\\"]*[^\\[\\](){}|\\n\\\"\\s/\\\\]", .string),
        (" (?<=: )\\S.*$", .string),
        ("\\b\\d+(\\.\\d+)?%?\\b", .number),
    ]
}

//
//  CypherRules.swift
//  CodeHighlighting
//
//  The regex rule table for Cypher.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Cypher: `//` and `/* */` comments (the language table adds them) — `--` is a relationship arrow
/// (`(a)--(b)`), never a comment; `'…'` and `"…"` strings with backslash escapes; `` `quoted names` ``;
/// `$parameters`; node labels and relationship types after `:`; the Cypher 25 clause and operator
/// keywords, case-insensitive.
extension RuleTables {
    static let cypher: [(String, TokenKind)] = [
        doubleQuoted,
        singleQuoted,
        callee,
        wordTrie(
            [
                "ACCESS", "ACTIVE", "ADD", "ADMIN", "ALL", "ALTER", "AND", "ANY", "AS", "ASC", "ASCENDING", "ASSERT", "BY", "CALL", "CASE",
                "CHANGE", "COLLECT", "CONSTRAINT", "CONTAINS", "COPY", "COUNT", "CREATE", "CSV", "DATABASE", "DEFAULT", "DELETE", "DENY",
                "DESC", "DESCENDING", "DETACH", "DISTINCT", "DROP", "EACH", "ELSE", "END", "ENDS", "EXISTS", "EXPLAIN", "FIELDTERMINATOR",
                "FILTER", "FINISH", "FOR", "FOREACH", "FROM", "FULLTEXT", "GRANT", "GRAPH", "HEADERS", "IF", "IN", "INDEX", "IS", "KEY",
                "LIMIT", "LOAD", "MATCH", "MERGE", "NEXT", "NODE", "NODES", "NOT", "OF", "OFFSET", "ON", "OPTIONAL", "OR", "ORDER",
                "PASSWORD", "PERIODIC", "PROFILE", "RANGE", "REL", "RELATIONSHIP", "REMOVE", "RENAME", "REPLACE", "REQUIRE", "REQUIRED",
                "RETURN", "REVOKE", "ROLE", "ROWS", "SET", "SHORTEST", "SHOW", "SKIP", "START", "STARTS", "STOP", "TEXT", "THEN", "TO",
                "TRANSACTIONS", "TYPE", "UNION", "UNIQUE", "UNWIND", "USE", "USER", "USING", "VECTOR", "WHEN", "WHERE", "WITH", "XOR",
                "YIELD",
            ],
            .keyword, caseInsensitive: true
        ),
        ("(?i)\\b(true|false|null)\\b", .number),
        ("`[^`\\n]*`", .variable),
        ("(?<=:)(?:[A-Z][A-Za-z0-9_]*\\b|`[^`\\n]*`)", .type),
        ("\\$(?:[A-Za-z_]\\w*|`[^`\\n]*`)", .property),
        decimal,
    ]
}

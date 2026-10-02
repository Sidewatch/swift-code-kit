//
//  SQLDialectFamilyRules.swift
//  CodeHighlighting
//
//  The words the SQL dialect tables (HiveQL, PL/SQL, PL/pgSQL) share.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The words the SQL dialect tables share: the standard statement, clause and operator keywords and the
/// standard type names, each dialect adding its own on top. Matched in any case.
extension RuleTables {
    static let sqlStandardKeywords = [
        "SELECT", "FROM", "WHERE", "INSERT", "INTO", "VALUES", "UPDATE", "SET", "DELETE", "MERGE", "CREATE", "ALTER",
        "DROP", "TRUNCATE", "TABLE", "VIEW", "INDEX", "SEQUENCE", "SCHEMA", "DATABASE", "TRIGGER", "FUNCTION",
        "PROCEDURE", "TYPE", "DOMAIN", "ROLE", "USER", "GRANT", "REVOKE", "ON", "TO", "WITH", "RECURSIVE", "AS", "AND",
        "OR", "NOT", "NULL", "IS", "IN", "EXISTS", "BETWEEN", "LIKE", "ESCAPE", "CASE", "WHEN", "THEN", "ELSE", "END",
        "IF", "JOIN", "INNER", "LEFT", "RIGHT", "FULL", "OUTER", "CROSS", "NATURAL", "USING", "GROUP", "BY", "ORDER",
        "HAVING", "LIMIT", "OFFSET", "FETCH", "FIRST", "NEXT", "ROWS", "ROW", "ONLY", "DISTINCT", "ALL", "ANY", "SOME",
        "UNION", "INTERSECT", "EXCEPT", "ASC", "DESC", "NULLS", "LAST", "PRIMARY", "KEY", "FOREIGN", "REFERENCES",
        "CONSTRAINT", "UNIQUE", "CHECK", "DEFAULT", "COLUMN", "ADD", "RENAME", "CASCADE", "RESTRICT", "BEGIN",
        "COMMIT", "ROLLBACK", "SAVEPOINT", "TRANSACTION", "RETURN", "RETURNS", "RETURNING", "DECLARE", "OVER",
        "PARTITION", "WINDOW", "RANGE", "PRECEDING", "FOLLOWING", "UNBOUNDED", "CURRENT", "FILTER", "WITHIN", "LATERAL",
        "TEMPORARY", "TEMP", "REPLACE", "OF", "FOR", "LOOP", "WHILE", "EXIT", "CONTINUE", "CALL", "EXECUTE",
        "LANGUAGE", "MATCHED", "GENERATED", "ALWAYS", "IDENTITY", "START", "INCREMENT", "CURSOR", "OPEN", "CLOSE",
        "EXCEPTION", "BEFORE", "AFTER", "INSTEAD", "EACH", "STATEMENT", "COMMENT", "LOCAL", "GLOBAL", "DATA",
        "WITHOUT", "ZONE", "AT", "CAST", "COLLATE", "EXPLAIN", "ANALYZE", "SHOW", "USE", "DESCRIBE",
    ]

    static let sqlStandardTypes = [
        "INT", "INTEGER", "SMALLINT", "BIGINT", "TINYINT", "DECIMAL", "NUMERIC", "REAL", "FLOAT", "DOUBLE",
        "PRECISION", "CHAR", "CHARACTER", "VARCHAR", "VARYING", "TEXT", "DATE", "TIME", "TIMESTAMP", "INTERVAL",
        "BOOLEAN", "BOOL", "BLOB", "CLOB", "BINARY", "VARBINARY",
    ]

    /// `words` as one case-insensitive whole-word rule of `kind`, its alternation folded into a prefix tree
    /// (`SE(?:LECT|T)`): a flat list of three hundred words is tried word by word at every letter, the
    /// tree one character at a time.
    static func sqlWords(_ words: [String], _ kind: TokenKind) -> (String, TokenKind) {
        ("(?i)\\b" + prefixTree(Set(words.map { $0.uppercased() })) + "\\b", kind)
    }
}

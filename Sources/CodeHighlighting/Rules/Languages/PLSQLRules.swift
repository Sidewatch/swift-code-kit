//
//  PLSQLRules.swift
//  CodeHighlighting
//
//  The regex rule table for Oracle PL/SQL.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Oracle PL/SQL: `--` and `/* */` comments and SQL*Plus `REM` lines, `'…'` strings where `''` is a
/// quote, `q'[…]'` alternative quoting with any bracket or character, `N'…'` national strings, the standard
/// keywords with PL/SQL's own, `%TYPE` / `%ROWTYPE` attributes, `<<labels>>`, the Oracle types, and numbers.
extension RuleTables {
    static let plsql: [(String, TokenKind)] = [
        dashComment,
        blockComment,
        ("(?i)^[ \\t]*REM(?:ARK)?\\b.*$", .comment),
        ("(?i)\\b[NQ]?Q'(?:\\[[\\s\\S]*?\\]|\\{[\\s\\S]*?\\}|\\([\\s\\S]*?\\)|<[\\s\\S]*?>|([^\\s\\[{(<])[\\s\\S]*?\\1)'", .string),
        ("(?i)(?:\\bN)?'(?:[^']|'')*'", .string),
        callee,
        sqlWords(
            sqlStandardKeywords + [
                "PACKAGE", "BODY", "IS", "ELSIF", "PRAGMA", "AUTONOMOUS_TRANSACTION", "EXCEPTION_INIT", "RAISE",
                "RAISE_APPLICATION_ERROR", "CONSTANT", "SUBTYPE", "RECORD", "VARRAY", "NOCOPY", "OUT", "REF",
                "DETERMINISTIC", "PIPELINED", "PARALLEL_ENABLE", "RESULT_CACHE", "AUTHID", "DEFINER", "GOTO", "BULK",
                "COLLECT", "FORALL", "SAVE", "EXCEPTIONS", "LIMIT", "PIPE", "PROMPT", "WHENEVER", "SQLERROR", "DEFINE",
                "UNDEFINE", "ACCEPT", "SPOOL", "TABLESPACE", "NOCACHE", "NOCYCLE", "CACHE", "CYCLE", "MINVALUE",
                "MAXVALUE", "MINUS", "CONNECT", "PRIOR", "NOCYCLE", "SIBLINGS", "ROWNUM", "ROWID", "LEVEL", "SYSDATE",
                "SYSTIMESTAMP", "DUAL", "EXTERNAL", "JAVA", "NAME", "LIBRARY", "OVERRIDING", "MEMBER", "STATIC",
                "FINAL", "INSTANTIABLE", "UNDER", "SELF", "OBJECT", "MAP", "ORDER", "SQLCODE", "SQLERRM", "FOUND",
                "NOTFOUND", "ISOPEN", "ROWCOUNT", "OTHERS", "NO_DATA_FOUND", "TOO_MANY_ROWS", "DUP_VAL_ON_INDEX",
                "IMMEDIATE", "BETWEEN", "REVERSE", "PIVOT", "UNPIVOT", "FLASHBACK", "PURGE", "COMPOUND", "FOLLOWS",
                "ENABLE", "DISABLE", "EDITIONABLE", "NONEDITIONABLE", "ACCESSIBLE", "SHARING", "MODIFY", "SYNONYM",
                "PUBLIC", "PRIVATE", "DIRECTORY", "CONTEXT", "AUDIT", "NOAUDIT", "LOCK", "MODE", "SHARE", "NOWAIT",
                "WAIT", "SKIP", "LOCKED", "OF", "INDICES", "VALUES", "KEEP", "DENSE_RANK", "IGNORE", "RESPECT",
            ], .keyword),
        sqlWords(
            sqlStandardTypes + [
                "NUMBER", "VARCHAR2", "NVARCHAR2", "NCHAR", "NCLOB", "RAW", "LONG", "PLS_INTEGER", "BINARY_INTEGER",
                "BINARY_FLOAT", "BINARY_DOUBLE", "SIMPLE_INTEGER", "NATURAL", "NATURALN", "POSITIVE", "POSITIVEN",
                "SIGNTYPE", "ROWID", "UROWID", "BFILE", "XMLTYPE", "SYS_REFCURSOR", "STRING",
            ], .type),
        ("(?i)%(?:TYPE|ROWTYPE|FOUND|NOTFOUND|ISOPEN|ROWCOUNT|BULK_ROWCOUNT|BULK_EXCEPTIONS)\\b", .keyword),
        ("<<[A-Za-z_]\\w*>>", .attribute),
        ("(?i)\\b(TRUE|FALSE)\\b", .number),
        ("\\b\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?[fFdD]?\\b|\\B\\.\\d+\\b", .number),
    ]
}

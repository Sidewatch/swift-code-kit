//
//  PLpgSQLRules.swift
//  CodeHighlighting
//
//  The regex rule table for PostgreSQL's SQL and PL/pgSQL.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// PostgreSQL and PL/pgSQL: `--` and `/* */` comments, `'…'` strings where `''` is a quote, `E'…'` strings
/// with backslash escapes, `U&'…'` / `B'…'` / `X'…'` literals, `"quoted identifiers"` left plain, and a
/// `$$…$$` or `$tag$…$tag$` literal that closes on its own line — a dollar-quoted function body spans
/// lines and is PL/pgSQL code, painted as code. Then the standard keywords with PostgreSQL's and
/// PL/pgSQL's own, the PostgreSQL types, `::casts`, `$1` parameters, and numbers.
extension RuleTables {
    static let plpgsql: [(String, TokenKind)] = [
        dashComment,
        blockComment,
        ("(?i)\\bE'(?:[^'\\\\]|\\\\[\\s\\S]|'')*'", .string),
        ("(?i)(?:\\bU&|\\b[BX])?'(?:[^']|'')*'", .string),
        ("\\$([A-Za-z_]\\w*)?\\$[^\\n]*?\\$\\1\\$", .string),
        callee,
        sqlWords(
            sqlStandardKeywords + [
                "ILIKE", "SIMILAR", "ELSIF", "ELSEIF", "PERFORM", "RAISE", "NOTICE", "WARNING", "INFO", "LOG", "DEBUG",
                "ERRCODE", "MESSAGE", "HINT", "DETAIL", "FOUND", "STRICT", "QUERY", "GET", "DIAGNOSTICS", "STACKED",
                "SQLSTATE", "SQLERRM", "OUT", "INOUT", "VARIADIC", "SETOF", "VOLATILE", "STABLE", "IMMUTABLE",
                "SECURITY", "DEFINER", "INVOKER", "COST", "ROWS", "PARALLEL", "SAFE", "UNSAFE", "RESTRICTED", "LEAKPROOF",
                "ALIAS", "CONSTANT", "FOREACH", "SLICE", "REVERSE", "ASSERT", "NEW", "OLD", "TG_OP", "CONCURRENTLY",
                "MATERIALIZED", "REFRESH", "EXTENSION", "OWNER", "AUTHORIZATION", "TABLESPACE", "INHERITS", "UNLOGGED",
                "LISTEN", "NOTIFY", "UNLISTEN", "VACUUM", "REINDEX", "CLUSTER", "COPY", "STDIN", "STDOUT", "CSV",
                "HEADER", "DELIMITER", "ENUM", "CONFLICT", "NOTHING", "DO", "EXCLUDED", "DEFERRABLE", "INITIALLY",
                "DEFERRED", "IMMEDIATE", "EXCLUDE", "INCLUDE", "OVERRIDING", "SYSTEM", "VALUE", "POLICY", "ROW",
                "LEVEL", "ENABLE", "DISABLE", "FORCE", "RESTART", "TRUNCATE", "SERVER", "WRAPPER", "FOREIGN", "OPTIONS",
                "PUBLICATION", "SUBSCRIPTION", "STATISTICS", "RULE", "ALSO", "NOTHING", "TABLESAMPLE", "ORDINALITY",
                "GROUPING", "SETS", "CUBE", "ROLLUP", "TIES", "VERBOSE", "BUFFERS", "COSTS", "FORMAT", "LOCK", "SHARE",
                "NOWAIT", "SKIP", "LOCKED", "OIDS", "PREPARE", "DEALLOCATE", "DISCARD", "RESET", "ATTACH", "DETACH",
                "REPLICA", "IDENTITY", "STORED", "VIRTUAL", "PROCEDURAL", "TRUSTED", "HANDLER", "VALIDATOR", "SECURITY_BARRIER",
                "WORK", "ISOLATION", "SERIALIZABLE", "READ", "COMMITTED", "REPEATABLE", "WRITE", "ABSOLUTE", "RELATIVE",
                "PRIOR", "SCROLL", "HOLD", "MOVE", "BACKWARD", "FORWARD", "NO", "INSTEAD",
            ], .keyword),
        sqlWords(
            sqlStandardTypes + [
                "SERIAL", "BIGSERIAL", "SMALLSERIAL", "MONEY", "BYTEA", "TIMESTAMPTZ", "TIMETZ", "UUID", "JSON", "JSONB",
                "XML", "INET", "CIDR", "MACADDR", "MACADDR8", "TSVECTOR", "TSQUERY", "POINT", "LINE", "LSEG", "BOX",
                "PATH", "POLYGON", "CIRCLE", "BIT", "VARBIT", "INT2", "INT4", "INT8", "FLOAT4", "FLOAT8", "OID",
                "REGCLASS", "RECORD", "VOID", "TRIGGER", "ANYELEMENT", "ANYARRAY", "INT4RANGE", "INT8RANGE", "NUMRANGE",
                "TSRANGE", "TSTZRANGE", "DATERANGE", "ARRAY", "REFCURSOR", "HSTORE", "CITEXT", "NAME",
            ], .type),
        ("(?i)%(?:TYPE|ROWTYPE)\\b", .keyword),
        ("::[A-Za-z_]\\w*(?:\\[\\])?", .type),
        ("\\$\\d+", .variable),
        ("(?i)\\b(TRUE|FALSE)\\b", .number),
        ("\\b(?:0[xX][0-9a-fA-F_]+|0[oO][0-7_]+|0[bB][01_]+|\\d[\\d_]*(?:\\.\\d+)?(?:[eE][+-]?\\d+)?)\\b|\\B\\.\\d+\\b", .number),
    ]
}

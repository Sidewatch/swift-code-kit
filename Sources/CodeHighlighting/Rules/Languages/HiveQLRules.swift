//
//  HiveQLRules.swift
//  CodeHighlighting
//
//  The regex rule table for HiveQL.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// HiveQL: `--` and `/* */` comments, `'…'` and `"…"` strings with backslash escapes (`\'` and `\"` are
/// quotes inside them), `` `quoted identifiers` `` left plain, `${hiveconf:name}` substitutions, the
/// standard keywords with Hive's own, the Hive types, and numbers with their `L` `S` `Y` `BD` suffixes.
extension RuleTables {
    static let hiveql: [(String, TokenKind)] = [
        dashComment,
        blockComment,
        ("'(?:[^'\\\\]|\\\\[\\s\\S])*'", .string),
        ("\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
        callee,
        sqlWords(
            sqlStandardKeywords + [
                "EXTERNAL", "PARTITIONED", "CLUSTERED", "SORTED", "BUCKETS", "STORED", "FORMAT", "DELIMITED", "FIELDS",
                "TERMINATED", "COLLECTION", "ITEMS", "KEYS", "LINES", "SERDE", "SERDEPROPERTIES", "TBLPROPERTIES",
                "LOCATION", "DISTRIBUTE", "SORT", "CLUSTER", "OVERWRITE", "LOAD", "INPATH", "SEMI", "ANTI", "RLIKE",
                "REGEXP", "TRANSFORM", "MAP", "REDUCE", "MSCK", "REPAIR", "DATABASES", "TABLES", "PARTITIONS",
                "FUNCTIONS", "COLUMNS", "STATISTICS", "COMPUTE", "SKEWED", "DIRECTORIES", "LIFECYCLE", "TABLESAMPLE",
                "BUCKET", "OUT", "PERCENT", "EXPORT", "IMPORT", "ARCHIVE", "UNARCHIVE", "TOUCH", "MATERIALIZED",
                "REBUILD", "DISABLE", "ENABLE", "REWRITE", "MACRO", "INPUTFORMAT", "OUTPUTFORMAT", "PURGE", "VERSION",
                "VIEW", "OWNER", "DBPROPERTIES", "ADMIN", "OPTION", "PRIVILEGES", "ROLES", "SCHEMAS", "UNIQUEJOIN",
                "CONF", "LOCK", "UNLOCK", "SHARED", "EXCLUSIVE", "COMPACT", "COMPACTIONS", "TRANSACTIONS", "ABORT",
                "DUMP", "REPL", "STATUS", "FILE", "FILES", "JAR", "JARS", "CONSTRAINTS", "NOVALIDATE", "RELY", "NORELY", "DIRECTORY",
                "TRANSACTIONAL", "MANAGED",
            ], .keyword),
        sqlWords(
            sqlStandardTypes + [
                "STRING", "ARRAY", "STRUCT", "UNIONTYPE", "TIMESTAMPLOCALTZ", "TEXTFILE", "SEQUENCEFILE", "ORC", "PARQUET", "AVRO",
                "RCFILE", "JSONFILE",
            ],
            .type),
        ("(?i)\\b(TRUE|FALSE)\\b", .number),
        ("\\$\\{[^}\\n]*\\}", .variable),
        ("\\b(?:0[xX][0-9a-fA-F]+|\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?(?:BD|[LSY])?)\\b|\\B\\.\\d+\\b", .number),
    ]
}

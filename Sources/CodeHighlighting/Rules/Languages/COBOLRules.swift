//
//  COBOLRules.swift
//  CodeHighlighting
//
//  The regex rule table for COBOL.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// COBOL: a `*` or `/` in column 7 is a comment line, `*>` a floating comment; a literal ends at its
/// line's end (a `-` continuation line opens a fresh quote) and `""` / `''` are quotes inside one;
/// the divisions, verbs and reserved words (case-insensitive) — a dashed reserved word like `END-IF` or
/// `COMP-5` is one word, and stays a keyword over the dashed-name, paragraph-name and number rules — level
/// numbers, and `PIC` clauses as types, their `9`s included.
extension RuleTables {
    static let cobol: [(String, TokenKind)] = [
        ("^.{6}\\*.*$", .comment),
        ("\\*>.*$", .comment),
        ("^.{6}/.*$", .comment),
        ("\"(?:[^\"\\n]|\"\")*(?:\"|(?=\\n)|\\z)", .string),
        ("'(?:[^'\\n]|'')*(?:'|(?=\\n)|\\z)", .string),
        ("\\b[A-Za-z][A-Za-z0-9]*-[A-Za-z0-9-]+\\b", .variable),
        ("^\\s*[A-Za-z0-9][A-Za-z0-9-]*\\.$", .function),
        ("^\\s*\\d{2}\\b", .number),
        ("\\b\\d+(\\.\\d+)?\\b", .number),
        ("(?i)(?<![\\w-])" + prefixTree(Set(cobolReservedWords)) + "(?![\\w-])", .keyword),
        ("(?i)\\bPIC(TURE)?\\s+(IS\\s+)?[XxAa9SsVvZz0-9NnUuGgEeBbPp/()+,.$*-]+", .type),
    ]

    /// The reserved words, dashed ones (`END-IF`, `I-O-CONTROL`, `COMP-5`) matched whole.
    static let cobolReservedWords = [
        "ACCEPT", "ACCESS", "ADD", "ADDRESS", "ADVANCING", "AFTER", "ALL", "ALLOCATE", "ALPHABET", "ALPHABETIC",
        "ALPHABETIC-LOWER", "ALPHABETIC-UPPER", "ALPHANUMERIC", "ALPHANUMERIC-EDITED", "ALSO", "ALTER", "ALTERNATE",
        "AND", "ANY", "ARE", "AREA", "AREAS", "ARGUMENT-NUMBER", "ARGUMENT-VALUE", "AS", "ASCENDING", "ASSIGN", "AT",
        "AUTHOR", "AUTO", "AUTO-SKIP", "AUTOMATIC", "AUTOTERMINATE", "BACK", "BACKGROUND-COLOR", "BASED", "BEEP",
        "BEFORE", "BELL", "BINARY", "BLANK", "BLINK", "BLOCK", "BOTTOM", "BY", "BYTE-LENGTH", "CALL", "CANCEL",
        "CHAINING", "CHARACTER", "CHARACTERS", "CLASS", "CLASS-ID", "CLOSE", "CODE", "CODE-SET", "COL", "COLLATING",
        "COLS", "COLUMN", "COLUMNS", "COMMA", "COMMAND-LINE", "COMMIT", "COMMON", "COMP", "COMP-1", "COMP-2", "COMP-3",
        "COMP-4", "COMP-5", "COMPUTATIONAL", "COMPUTATIONAL-3", "COMPUTE", "CONFIGURATION", "CONSTANT", "CONTAINS",
        "CONTENT", "CONTINUE", "CONTROL", "CONTROLS", "CONVERTING", "COPY", "CORR", "CORRESPONDING", "COUNT", "CRT",
        "CURRENCY", "CURSOR", "CYCLE", "DATA", "DATE", "DAY", "DAY-OF-WEEK", "DE", "DEBUGGING", "DECIMAL-POINT",
        "DECLARATIVES", "DEFAULT", "DELETE", "DELIMITED", "DELIMITER", "DEPENDING", "DESCENDING", "DETAIL", "DISK",
        "DISPLAY", "DIVIDE", "DIVISION", "DOWN", "DUPLICATES", "DYNAMIC", "EBCDIC", "ELSE", "END", "END-ACCEPT",
        "END-ADD", "END-CALL", "END-COMPUTE", "END-DELETE", "END-DISPLAY", "END-DIVIDE", "END-EVALUATE", "END-IF",
        "END-MULTIPLY", "END-OF-PAGE", "END-PERFORM", "END-READ", "END-RETURN", "END-REWRITE", "END-SEARCH",
        "END-START", "END-STRING", "END-SUBTRACT", "END-UNSTRING", "END-WRITE", "ENTRY", "ENVIRONMENT",
        "ENVIRONMENT-NAME", "ENVIRONMENT-VALUE", "EOL", "EOP", "EOS", "EQUAL", "ERASE", "ERROR", "ESCAPE", "EVALUATE",
        "EVERY", "EXCEPTION", "EXCLUSIVE", "EXIT", "EXTEND", "EXTERNAL", "FALSE", "FD", "FILE", "FILE-CONTROL",
        "FILE-ID", "FILLER", "FINAL", "FIRST", "FIXED", "FLOAT-LONG", "FLOAT-SHORT", "FOOTING", "FOR",
        "FOREGROUND-COLOR", "FOREVER", "FORMAT", "FREE", "FROM", "FULL", "FUNCTION", "FUNCTION-ID", "GENERATE",
        "GIVING", "GLOBAL", "GO", "GOBACK", "GREATER", "GROUP", "HEADING", "HIGH-VALUES", "HIGHLIGHT", "I-O",
        "I-O-CONTROL", "ID", "IDENTIFICATION", "IF", "IGNORE", "IGNORING", "IN", "INDEX", "INDEXED", "INDICATE",
        "INITIAL", "INITIALIZE", "INITIALIZED", "INITIATE", "INPUT", "INPUT-OUTPUT", "INSPECT", "INTO", "INTRINSIC",
        "INVALID", "INVOKE", "IS", "JUST", "JUSTIFIED", "KEY", "LABEL", "LAST", "LEADING", "LEFT", "LENGTH", "LESS",
        "LIMIT", "LIMITS", "LINAGE", "LINAGE-COUNTER", "LINE", "LINES", "LINKAGE", "LOCAL-STORAGE", "LOCALE", "LOCK",
        "LOW-VALUES", "LOWLIGHT", "MANUAL", "MEMORY", "MERGE", "METHOD-ID", "MINUS", "MODE", "MOVE", "MULTIPLE",
        "MULTIPLY", "NATIONAL", "NATIONAL-EDITED", "NATIVE", "NEGATIVE", "NEXT", "NO", "NOT", "NULL", "NULLS", "NUMBER",
        "NUMBERS", "NUMERIC", "NUMERIC-EDITED", "OBJECT", "OBJECT-COMPUTER", "OCCURS", "OF", "OFF", "OMITTED", "ON",
        "ONLY", "OPEN", "OPTIONAL", "OR", "ORDER", "ORGANIZATION", "OTHER", "OUTPUT", "OVERFLOW", "OVERLINE",
        "PACKED-DECIMAL", "PADDING", "PAGE", "PARAGRAPH", "PERFORM", "PIC", "PICTURE", "PLUS", "POINTER", "POSITION",
        "POSITIVE", "PRESENT", "PREVIOUS", "PRINTER", "PRINTING", "PROCEDURE", "PROCEDURE-POINTER", "PROCEDURES",
        "PROCEED", "PROGRAM", "PROGRAM-ID", "PROGRAM-POINTER", "PROMPT", "PROPERTY", "QUOTE", "QUOTES", "RAISE",
        "RAISING", "RANDOM", "RD", "READ", "RECORD", "RECORDING", "RECORDS", "RECURSIVE", "REDEFINES", "REEL",
        "REFERENCE", "RELATIVE", "RELEASE", "REMAINDER", "REMOVAL", "RENAMES", "REPLACING", "REPORT", "REPORTING",
        "REPORTS", "REPOSITORY", "REQUIRED", "RESERVE", "RESUME", "RETURN", "RETURNING", "REVERSE-VIDEO", "REWIND",
        "REWRITE", "RIGHT", "ROLLBACK", "ROUNDED", "RUN", "SAME", "SCREEN", "SCROLL", "SD", "SEARCH", "SECTION",
        "SECURE", "SEGMENT-LIMIT", "SELECT", "SELF", "SENTENCE", "SEPARATE", "SEQUENCE", "SEQUENTIAL", "SET", "SHARING",
        "SIGN", "SIGNED", "SIGNED-INT", "SIGNED-LONG", "SIGNED-SHORT", "SIZE", "SORT", "SORT-MERGE", "SOURCE",
        "SOURCE-COMPUTER", "SPACE", "SPACES", "SPECIAL-NAMES", "STANDARD", "STANDARD-1", "STANDARD-2", "START",
        "STATUS", "STOP", "STRING", "SUBKEY", "SUBTRACT", "SUM", "SUPER", "SUPPRESS", "SYMBOLIC", "SYNC",
        "SYNCHRONIZED", "TALLYING", "TAPE", "TERMINATE", "TEST", "THAN", "THEN", "THROUGH", "THRU", "TIME", "TIMES",
        "TO", "TOP", "TRAILING", "TRANSFORM", "TRUE", "TYPE", "TYPEDEF", "UNDERLINE", "UNIT", "UNLOCK", "UNSIGNED",
        "UNSIGNED-INT", "UNSIGNED-LONG", "UNSIGNED-SHORT", "UNSTRING", "UNTIL", "UP", "UPDATE", "UPON", "USAGE", "USE",
        "USING", "VALIDATE", "VALUE", "VALUES", "VARYING", "WAIT", "WHEN", "WITH", "WORDS", "WORKING-STORAGE", "WRITE",
        "YYYYDDD", "YYYYMMDD", "ZERO", "ZEROES", "ZEROS",

    ]
}

//
//  StataRules.swift
//  CodeHighlighting
//
//  The regex rule table for Stata.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Stata: `*` whole-line, `//` and `///` comments and `/* */` blocks (the language table adds them);
/// `"…"` strings and `` `"…"' `` compound strings, either of which may hold `` `macro' `` references;
/// a `` `local' `` macro outside a string opens nothing — `'` is never a quote, so `A'` (a transpose) and
/// `` `name' `` stay code; `$global` / `${global}` macros; commands and Mata words as keywords; `.`, `.a`
/// missing values and `.5` decimals as numbers.
extension RuleTables {
    static let stata: [(String, TokenKind)] = [
        ("`\"(?:`\"[^\\n]*?\"'|(?!\"')[^\\n])*\"'", .string),
        ("(?<!`)\"(?:[^\"\\\\`\\n]|\\\\.|`[^'\\n]*'|`)*\"", .string),
        wordTrie(
            [
                "about", "adopath", "anova", "append", "args", "as", "assert", "bayes", "bayesstats", "bootstrap", "break",
                "by", "bysort", "capture", "cd", "char", "clear", "codebook", "collapse", "collect", "compress", "confirm",
                "continue", "contrast", "correlate", "count", "cwf", "decode", "define", "describe", "destring", "didregress",
                "display", "do", "drop", "dsregress", "dtable", "duplicates", "egen", "else", "encode", "end", "ereturn",
                "error", "estat", "estimates", "eststo", "etable", "exit", "export", "file", "foreach", "format", "forvalues",
                "frame", "frget", "frlink", "gen", "generate", "gettoken", "global", "glm", "graph", "gsort", "help",
                "histogram", "if", "import", "in", "include", "infile", "input", "insheet", "ivregress", "joinby", "jupyter",
                "keep", "label", "lasso", "levelsof", "lincom", "list", "local", "log", "logit", "mac", "macro", "margins",
                "marginsplot", "marksample", "mat", "mata", "matrix", "merge", "mi", "mixed", "nlcom", "noisily", "notes",
                "of", "order", "outsheet", "poisson", "post", "postclose", "postfile", "predict", "preserve", "probit",
                "program", "putdocx", "putexcel", "putpdf", "pwcorr", "python", "qui", "quietly", "recode", "regress",
                "rename", "replace", "reshape", "restore", "return", "run", "save", "saveold", "scalar", "sem", "set",
                "sort", "stcox", "stset", "summarize", "sum", "syntax", "sysuse", "table", "tabstat", "tabulate", "tab",
                "teffects", "tempfile", "tempname", "tempvar", "test", "testparm", "timer", "tokenize", "tostring", "ttest",
                "twoway", "use", "using", "version", "which", "while", "xtreg", "xtset",
                // Commands and `set` / `estimates` / `frame` subcommands that read as words of their own.
                "alpha", "copy", "gamma", "impute", "mean", "more", "on", "se", "simulate", "total", "type", "vif",
            ], .keyword),
        // A merge's match type: `m:1`, `1:m`, `m:m`.
        ("\\bm(?=:[1m]\\b)|(?<=\\b[1m]:)m\\b", .keyword),
        wordTrie(
            [
                "byte", "int", "long", "float", "double", "str", "strL", "real", "string", "numeric", "pointer",
                "transmorphic", "void", "colvector", "rowvector", "varlist", "newlist", "numlist", "varname",
            ], .type),
        ("\\bstr(?:\\d+|L)\\b", .type),
        ("`[^'\\n]*'", .property),
        ("\\$\\{?[A-Za-z_]\\w*\\}?", .property),
        ("(?<![\\w.])(?:\\d+(?:\\.\\d+)?|\\.\\d+)(?:[eE][+-]?\\d+)?\\b|\\b0[xX][0-9a-fA-F]+\\b|(?<![\\w.])\\.[a-z]?(?![\\w.])", .number),
        ("\\b[A-Za-z_]\\w*(?=\\()", .function),
    ]
}

//
//  NushellRules.swift
//  CodeHighlighting
//
//  The regex rule table for Nushell.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Nushell, read the way VS Code's grammar reads it: the first word of a pipeline element is a command
/// (a built-in one a keyword, any other an external command in the type colour), the words after it are
/// bare-word strings, `--flags` open with a keyword, signatures name their types, and the operators
/// (`=`, `|`, `==`, `..`, `and`, `bit-or`) are keywords. Also `#` comments that start a word (`r#'…'#` is a
/// raw string, not a comment), `"…"`, `'…'`, `` `…` ``, `r#'…'#` raw strings, `$"…(expr)…"` interpolations
/// whose `( … )` may hold quotes, `./paths`, numbers with their units (`10kb`, `500ms`, `1.5MiB`), dates,
/// binary literals (`0x[FF 00]`), `$variables` and `@attributes`.
extension RuleTables {
    static let nushell: [(String, TokenKind)] = [
        (nushellCommandStart + #"(?![0-9])[.\w][-!.\w]*+"# + nushellNotKey, .type),
        (nushellCommandStart + "(?:(?:ansi|char) \\w+|" + prefixTree(Set(nushellBuiltins)) + ")(?![-\\w])" + nushellNotKey, .keyword),
        (#"\b(?<![-./:\\])(?:break|continue|else(?: if)?|for|if|loop|mut|return|try|while|catch|finally)(?![-./:\w\\])"#, .keyword),
        (#" (?:[-*+/]=?|//|\*\*|!=|[<=>]=?|[!=]~|\+\+=?|=>)(?= |$)"#, .keyword),
        (#"\||\.\.(?:\.(?=[^\]}\s])|<)?"#, .keyword),
        ("[ (]" + nushellWordOperators + "(?=[ )]|$)", .keyword),
        (#"[\s(\[]-{1,2}(?=[A-Za-z?])"#, .keyword),
        (#":(?<=[\w?"']:)(?=[ \t])"#, .keyword),
        (#"(?:\??:|->)[ \t]*\w+(?:-\w+)*"#, .type),
        (#"\b(?:list|record|table|oneof)<[^>\n]*>|\]:[ \t]*\[[^\]\n]*\]"#, .type),
        (#"\b(?:export[ \t]+)?(?:def|extern)(?:[ \t]+--\w+)*[ \t]+(?:[-\w]+|"[- \w]+"|'[- \w]+'|`[- \w]+`)"#, .function),
        (#"\b(?:export[ \t]+)?alias[ \t]+[-!\w]+(?=[ \t]*=)"#, .function),
        (#"\b(?:export[ \t]+)?(?:def(?:[ \t]+--\w+)*|extern|alias)\b"#, .keyword),
        (#"^[ \t]*(?:export[ \t]+)?use\b.*$"#, .keyword),
        // In a record literal (`{name: reload, qty: 12}`) a key is a name, the colon after it the operator, and a
        // bare value a bare-word string; the signature rule above would paint the value a type.
        (nushellInRecord + #"\b(?=[A-Za-z_][-\w]*\??:[ \t])(?<=[{,][ \t]{0,8})[A-Za-z_][-\w]*\??"#, .property),
        (nushellInRecord + #":(?<=[\w?]:)(?=[ \t])"#, .keyword),
        (nushellInRecord + #"\b(?=[A-Za-z_][-\w]*[ \t]*[,}])(?<=:[ \t]{1,8})(?!(?:true|false|null)(?![-\w]))[A-Za-z_][-\w]*"#, .string),
        (#"\b(?<!\^)(?:true|false|null)\b"#, .number),
        (
            #"(?<![-\w])[-+]?(?:(?i:nan|infinity|inf)|\d[\d_]*(?:\.\d[\d_]*)?(?:[eE][-+]?\d[\d_]*)?"#
                + nushellUnits + #"?)(?:(?![.\w])|(?=\.\.))"#, .number
        ),
        (#"(?<![-\w])0(?:x[0-9a-fA-F_]+|o[0-7_]+|b[01_]+)(?![.\w])|\b0[xob]\[[^\]\n]*\]"#, .number),
        (#"\b\d{4}-\d{2}-\d{2}(?:T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:[+-]\d{2}:?\d{2}|Z)?)?\b"#, .number),
        ("\\$[A-Za-z_]\\w*", .type),
        ("^[ \\t]*@[\\w-]+", .attribute),
        ("#(?<![^\\s;|(\\[{]#).*$", .comment),
        ("r(#+)'[\\s\\S]*?'\\1", .string),
        nushellInterpolated(quote: "\""),
        nushellInterpolated(quote: "'"),
        // A `def` or `extern` name in quotes is the command's name, not a string: neither of its quotes opens one.
        (#""(?<!(?:\bdef|\bextern|\bdef --env|\bdef --wrapped) ")(?![ \t]*\[)(?:[^"\\]|\\[\s\S])*""#, .string),
        singleQuotedPlain,
        backQuoted,
        // A path opens on its `../`, `./` or `~/` and then checks that nothing word-like precedes it.
        ("(?:\\.\\./(?<![\\w$.]\\.\\./)|\\./(?<![\\w$.]\\./)|~/(?<![\\w$.]~/))[^\\s|;)\\]}]*", .string),
        // `use` names a module by path (`std/util`, `./module.nu`); a plain name is a namespace.
        (#"[ \t](?<=\buse[ \t])[.~/]?[-\w]*[./~][^\s\[]*"#, .string),
        // `--glob=**/*.rs`: a flag's `=value` is a bare-word string.
        (#"=(?<=--[\w-]{1,40}=)[^\s\]"'(),;\[{|}]+"#, .string),
        // A word in a command's arguments is a bare-word string, and so is a glob where a command would be.
        (nushellBareWord, .string),
        (nushellListWord, .string),
        (#"[*?](?<=(?:^|[|;({,=])[ \t]{0,8}[*?])[^\]"'(),;\[{|}\s]*"#, .string),
    ]

    /// Where a command starts: a line's first word, or the first after `|`, `;`, `(`, `{`, `,` or `=`.
    private static let nushellCommandStart = #"(?:^|[|;({,=])[ \t]*\^?"#

    /// After a word where a command would start: not a record key, a word followed by `:` and a blank (`{name: x}`).
    private static let nushellNotKey = #"(?!\??:[ \t])"#

    /// One-line record literals, `{` and a key to the matching `}` (one level of nesting), stepping over strings
    /// and comments so a brace inside one does not count.
    private static let nushellInRecord = RuleScope.marker(
        steppingOver: [#""(?:[^"\\\n]|\\.)*""#, "'[^'\\n]*'", "#.*"],
        regions: #"\{(?=[ \t]*(?:[-\w]+|"[^"\n]*")\??:[ \t])(?:[^{}\n"]|"(?:[^"\\\n]|\\.)*"|\{(?:[^{}\n"]|"(?:[^"\\\n]|\\.)*")*\})*\}"#,
        within: 2000)

    /// The word operators, as one group.
    private static let nushellWordOperators =
        "(?:mod|in|not-in|not-like|not-has|not|and|or|xor|bit-or|bit-and|bit-xor|bit-shl|bit-shr|starts-with|ends-with|like|has)"

    /// The units a number may carry: durations and file sizes.
    private static let nushellUnits =
        "(?i:ns|us|µs|ms|sec|min|hr|day|wk|b|kb|mb|gb|tb|pb|eb|zb|kib|mib|gib|tib|pib|eib|zib)"

    /// A bare word in argument position: after another word of the same command (the spaces before it are
    /// part of the match, so the matcher only tries where a space follows a word), or first in a `[ … ]` list;
    /// and not a number, flag, operator, keyword, record key, or a name a declaration introduces.
    private static let nushellBareWord =
        nushellOutsideUse
        + #"[ \t](?<=(?:[^\s|;({}=:,<>\[-]|[=!<>~+]=|[=!]~|[^-]>)[ \t])[ \t]{0,7}"# + nushellBareToken

    /// A bare word first in a `[ … ]` list (not a signature's `]: [` input/output list); a glob there stays plain.
    private static let nushellListWord = nushellOutsideUse + #"\b(?<=\[)(?<!\]:[ \t]\[)"# + nushellBareToken

    /// The bare word itself, with everything it must not be.
    private static let nushellBareToken: String = {
        let number =
            #"[-+]?(?:\d[\d_]*(?:\.\d[\d_]*)?(?:[eE][-+]?\d+)?"# + nushellUnits
            + #"?|(?i:nan|inf(?:inity)?)|0x[0-9a-fA-F_]+|0o[0-7_]+|0b[01_]+|\d{4}-\d{2}-\d{2}(?:T[\d:.]+(?:[+-][\d:]+|Z)?)?)"#
            + #"(?=[\s)\]},;|]|$|\.\.)"#
        let words =
            "(?:" + nushellWordOperators.dropFirst(3).dropLast()
            + "|break|continue|else|for|if|loop|mut|return|try|while|catch|finally|true|false|null)(?=[\\s)\\]}|;,]|$)"
        // The second word of a built-in with subcommands (`math sum`, `str trim`, `export def`) is part of its name.
        let multiword = nushellBuiltins.filter { $0.contains(" ") }.map { $0.split(separator: " ", maxSplits: 1) }
        let subcommand =
            "(?!(?=" + prefixTree(Set(multiword.map { String($0[1]) })) + "(?![-\\w]))(?<="
            + nushellCommandStart.replacingOccurrences(of: "*", with: "{0,8}") + prefixTree(Set(multiword.map { String($0[0]) }))
            + "[ \\t]{1,8}))"
        let notValue =
            "(?!" + number + #"|--?[A-Za-z?]|->|(?:[-*+/]=?|//|\*\*|!=|[<=>]=?|[!=]~|\+\+=?|=>)(?=\s|$)|\.\.|0[xob]\[|"#
            + words + #"|[-\w]+\??:(?:\s|$))"# + subcommand
        // Neither a word of a quoted `def` name nor a byte of a `0x[…]` literal.
        let notInside = #"(?![- \w]*+"[ \t]*\[)(?![0-9a-fA-F]{1,2}(?=[\s\]])(?<=\b0[xob]\[[^\]\n]{0,40}))"#
        let notNamed = #"(?<!(?:\b(?:def|alias|extern|module|const|let|mut|for|ansi|char)|--env|--wrapped)[ \t])"#
        let first = ##"(?=[^\s"#$'(,;\[{|)\]}])"##
        return first + notValue + notInside + notNamed + ##"[^\s"#$'(,;\[{|)\]}][^\]"'(),;\[{|}\s]*"##
    }()

    /// Every line but a `use` line, whose words after the module are the names it imports.
    private static let nushellOutsideUse = RuleScope.marker(
        opens: ["(?m:^)(?![ \\t]*(?:export[ \\t]+)?use\\b)"], closes: ["\\n"], within: 2000)

    /// The commands Nushell ships, subcommands included (`math round`, `str trim`), as VS Code's grammar
    /// lists them.
    static let nushellBuiltins = [
        "alias", "all", "ansi", "ansi gradient", "ansi link", "ansi strip", "any", "append", "ast", "attr", "attr category",
        "attr deprecated", "attr example", "attr search-terms", "bits", "bits and", "bits not", "bits or", "bits rol",
        "bits ror", "bits shl", "bits shr", "bits xor", "break", "bytes", "bytes add", "bytes at", "bytes build",
        "bytes collect", "bytes ends-with", "bytes index-of", "bytes length", "bytes remove", "bytes replace", "bytes reverse",
        "bytes split", "bytes starts-with", "cal", "cd", "char", "chunk-by", "chunks", "clear", "collect", "columns",
        "commandline", "commandline edit", "commandline get-cursor", "commandline set-cursor", "compact", "complete", "config",
        "config env", "config flatten", "config nu", "config reset", "config use-colors", "const", "continue", "cp", "date",
        "date format", "date from-human", "date humanize", "date list-timezone", "date now", "date to-timezone", "debug",
        "debug env", "debug experimental-options", "debug info", "debug profile", "decode", "decode base32", "decode base32hex",
        "decode base64", "decode hex", "def", "default", "describe", "detect", "detect columns", "do", "drop", "drop column",
        "drop nth", "dt", "dt add", "dt diff", "dt format", "dt now", "dt part", "dt to", "dt utcnow", "du", "each",
        "each while", "echo", "emoji", "encode", "encode base32", "encode base32hex", "encode base64", "encode hex",
        "enumerate", "error", "error make", "every", "exec", "exit", "explain", "explore", "export", "export alias",
        "export const", "export def", "export extern", "export module", "export use", "export-env", "extern", "file", "fill",
        "filter", "find", "first", "flatten", "for", "format", "format bits", "format date", "format duration",
        "format filesize", "format number", "format pattern", "from", "from csv", "from eml", "from ics", "from ini",
        "from json", "from msgpack", "from msgpackz", "from nuon", "from ods", "from parquet", "from plist", "from ssv",
        "from toml", "from tsv", "from url", "from vcf", "from xlsx", "from xml", "from yaml", "from yml", "generate", "get",
        "glob", "grid", "group-by", "gstat", "hash", "hash md5", "hash sha256", "headers", "help", "help aliases",
        "help commands", "help escapes", "help externs", "help modules", "help operators", "help pipe-and-redirect", "hide",
        "hide-env", "histogram", "history", "history import", "history session", "http", "http delete", "http get", "http head",
        "http options", "http patch", "http post", "http put", "if", "ignore", "inc", "input", "input list", "input listen",
        "insert", "inspect", "interleave", "into", "into binary", "into bool", "into cell-path", "into datetime",
        "into duration", "into filesize", "into float", "into glob", "into int", "into record", "into sqlite", "into string",
        "into value", "is-admin", "is-empty", "is-not-empty", "is-terminal", "items", "job", "job flush", "job id", "job kill",
        "job list", "job recv", "job send", "job spawn", "job tag", "job unfreeze", "join", "json path", "jwalk", "keybindings",
        "keybindings default", "keybindings list", "keybindings listen", "kill", "last", "length", "let", "let-env", "lines",
        "load-env", "loop", "ls", "match", "math", "math abs", "math arccos", "math arccosh", "math arcsin", "math arcsinh",
        "math arctan", "math arctanh", "math avg", "math ceil", "math cos", "math cosh", "math exp", "math floor", "math ln",
        "math log", "math max", "math median", "math min", "math mode", "math product", "math round", "math sin", "math sinh",
        "math sqrt", "math stddev", "math sum", "math tan", "math tanh", "math variance", "merge", "merge deep", "metadata",
        "metadata access", "metadata set", "mkdir", "mktemp", "module", "move", "mut", "mv", "nu-check", "nu-highlight", "open",
        "overlay", "overlay hide", "overlay list", "overlay new", "overlay use", "panic", "par-each", "parse", "path",
        "path basename", "path dirname", "path exists", "path expand", "path join", "path parse", "path relative-to",
        "path self", "path split", "path type", "plugin", "plugin add", "plugin list", "plugin rm", "plugin stop", "plugin use",
        "polars", "polars agg", "polars agg-groups", "polars all-false", "polars all-true", "polars append", "polars arg-max",
        "polars arg-min", "polars arg-sort", "polars arg-true", "polars arg-unique", "polars arg-where", "polars as",
        "polars as-date", "polars as-datetime", "polars cache", "polars cast", "polars col", "polars collect", "polars columns",
        "polars concat", "polars concat-str", "polars contains", "polars convert-time-zone", "polars count",
        "polars count-null", "polars cumulative", "polars cut", "polars datepart", "polars decimal", "polars drop",
        "polars drop-duplicates", "polars drop-nulls", "polars dummies", "polars explode", "polars expr-not", "polars fetch",
        "polars fill-nan", "polars fill-null", "polars filter", "polars filter-with", "polars first", "polars flatten",
        "polars get", "polars get-day", "polars get-hour", "polars get-minute", "polars get-month", "polars get-nanosecond",
        "polars get-ordinal", "polars get-second", "polars get-week", "polars get-weekday", "polars get-year",
        "polars group-by", "polars horizontal", "polars implode", "polars integer", "polars into-df", "polars into-dtype",
        "polars into-lazy", "polars into-nu", "polars into-repr", "polars into-schema", "polars is-duplicated", "polars is-in",
        "polars is-not-null", "polars is-null", "polars is-unique", "polars join", "polars join-where", "polars last",
        "polars len", "polars list-contains", "polars lit", "polars lowercase", "polars math", "polars max", "polars mean",
        "polars median", "polars min", "polars n-unique", "polars not", "polars open", "polars otherwise", "polars over",
        "polars pivot", "polars profile", "polars qcut", "polars quantile", "polars query", "polars rename", "polars replace",
        "polars replace-time-zone", "polars reverse", "polars rolling", "polars sample", "polars save", "polars schema",
        "polars select", "polars set", "polars set-with-idx", "polars shape", "polars shift", "polars slice", "polars sort-by",
        "polars std", "polars store-get", "polars store-ls", "polars store-rm", "polars str-join", "polars str-lengths",
        "polars str-replace", "polars str-replace-all", "polars str-slice", "polars str-split", "polars str-strip-chars",
        "polars strftime", "polars struct-json-encode", "polars sum", "polars summary", "polars take", "polars truncate",
        "polars unique", "polars unnest", "polars unpivot", "polars uppercase", "polars value-counts", "polars var",
        "polars when", "polars with-column", "port", "prepend", "print", "ps", "query", "query db", "query git", "query json",
        "query web", "query webpage-info", "query xml", "random", "random binary", "random bool", "random chars", "random dice",
        "random float", "random int", "random uuid", "reduce", "regex", "registry", "registry query", "reject", "rename",
        "return", "reverse", "rm", "roll", "roll down", "roll left", "roll right", "roll up", "rotate", "run-external",
        "run-internal", "save", "schema", "scope", "scope aliases", "scope commands", "scope engine-stats", "scope externs",
        "scope modules", "scope variables", "select", "seq", "seq char", "seq date", "shuffle", "skip", "skip until",
        "skip while", "sleep", "slice", "sort", "sort-by", "source", "source-env", "split", "split cell-path", "split chars",
        "split column", "split list", "split row", "split words", "start", "stor", "stor create", "stor delete", "stor export",
        "stor import", "stor insert", "stor open", "stor reset", "stor update", "str", "str camel-case", "str capitalize",
        "str compress", "str contains", "str decompress", "str dedent", "str deunicode", "str distance", "str downcase",
        "str ends-with", "str expand", "str indent", "str index-of", "str join", "str kebab-case", "str length",
        "str pascal-case", "str replace", "str reverse", "str screaming-snake-case", "str shl-quote", "str shl-split",
        "str similarity", "str slug", "str snake-case", "str starts-with", "str stats", "str substring", "str title-case",
        "str trim", "str upcase", "str wrap", "stress_internals", "sys", "sys cpu", "sys disks", "sys host", "sys mem",
        "sys net", "sys temp", "sys users", "table", "take", "take until", "take while", "tee", "term", "term query",
        "term size", "timeit", "to", "to csv", "to html", "to json", "to md", "to msgpack", "to msgpackz", "to nuon",
        "to parquet", "to plist", "to text", "to toml", "to tsv", "to xml", "to yaml", "to yml", "touch", "transpose", "try",
        "tutor", "ulimit", "uname", "uniq", "uniq-by", "update", "update cells", "upsert", "url", "url build-query",
        "url decode", "url encode", "url join", "url parse", "url split-query", "use", "values", "version", "version check",
        "view", "view blocks", "view files", "view ir", "view source", "view span", "watch", "where", "which", "while",
        "whoami", "window", "with-env", "wrap", "zip",
    ]

    /// `$"…"` / `$'…'`: a `( … )` hole may hold quoted strings and one more level of parentheses.
    private static func nushellInterpolated(quote: String) -> (String, TokenKind) {
        let escape = quote == "\"" ? "|\\\\[\\s\\S]" : ""
        let hole = "\\((?:[^()\"']|\"(?:[^\"\\\\\\n]|\\\\.)*\"|'[^'\\n]*'|\\((?:[^()\"']|\"[^\"\\n]*\"|'[^'\\n]*')*\\))*\\)"
        return ("\\$\(quote)(?>[^\(quote)\\\\(]+\(escape)|\(hole)|\\(|\\\\)*\(quote)", .string)
    }
}

//
//  ABAPRules.swift
//  CodeHighlighting
//
//  The regex rule table for ABAP.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// ABAP: `*` comment lines, `"` trailing comments and `##` pragmas, `'…'` and backtick strings and `|…|`
/// templates (one line, `\\|` an escaped bar), the case-insensitive statement words and operators (the
/// words VS Code's grammar knows, hyphenated ones such as `READ-ONLY` whole), `TEXT-001` text symbols,
/// `METHOD name` implementations (`intf~name`: the interface a type), `ls_`/`lt_` variables, `-` structure
/// components.
extension RuleTables {
    static let abap: [(String, TokenKind)] = [
        ("^\\*.*$", .comment),
        ("\".*$", .comment),
        ("(?<!\\S)##[^,.:\\s]*", .comment),
        ("'(?:[^'\\n]|'')*'", .string),
        ("`(?:[^`\\n]|``)*`", .string),
        ("\\|(?:\\\\.|[^|\\\\\\n])*\\|", .string),
        // `TYPE name`: the name is a type; `TYPE` itself (and a keyword such as `REF`) is repainted below.
        ("(?i)\\btype[ \\t]{1,4}[a-z_]\\w*", .type),
        ("(?i)(?<![-\\w])" + prefixTree(Set(abapKeywords)) + "(?![-\\w])", .keyword),
        (" (?:=|<>|<=|>=|<|>|\\*\\*|[-*+/%]|&&?|\\?=|[-+/*]=|&&?=)(?= )", .keyword),
        ("(?i)\\btext(?=-\\w{1,3}\\b)", .keyword),
        ("(?i)\\b(lv|lt|ls|lo|lr|lc|gv|gt|gs|go|gr|gc|iv|it|is|io|ev|et|es|eo|cv|ct|cs|co|rv|rt|rs|ro|wa)_\\w+", .variable),
        ("<[a-z_]\\w*>", .variable),
        ("\\b[a-z_]\\w*-[a-z_]\\w*\\b", .property),
        ("\\b\\d+(\\.\\d+)?\\b", .number),
        ("\\b[a-z_]\\w*(?=\\()", .function),
        // `METHOD name.` names the method it implements; `METHOD intf~name.` the interface too.
        ("(?i)\\bmethod[ \\t]+[/\\w~]+", .function),
        ("(?i)\\bmethod[ \\t]+[/\\w]+(?=~)", .type),
        ("(?i)\\bmethod\\b", .keyword),
    ]

    /// The statement words, additions, operators and built-in type words, lowercase.
    static let abapKeywords = [
        "abap-source", "abstract", "accept", "accepting", "access", "according", "action", "activation", "actual", "add",
        "add-corresponding", "adjacent", "after", "alias", "aliases", "all", "allocate", "amdp", "analysis", "analyzer", "and",
        "append", "appending", "application", "archive", "area", "arithmetic", "as", "ascending", "assert", "assign",
        "assigned", "assigning", "association", "asynchronous", "at", "attributes", "authority", "authority-check",
        "authorization", "auto", "back", "background", "backward", "badi", "base", "before", "begin", "behavior", "between",
        "binary", "bit", "bit-and", "bit-not", "bit-or", "bit-xor", "blank", "blanks", "block", "blocks", "boolc", "bound",
        "boundaries", "bounds", "boxed", "break", "break-point", "buffer", "by", "bypassing", "byte", "byte-ca", "byte-cn",
        "byte-co", "byte-cs", "byte-na", "byte-ns", "byte-order", "ca", "call", "calling", "case", "cast", "casting", "catch",
        "cds", "centered", "change", "changing", "channels", "char-to-hex", "character", "check", "checkbox", "cid", "circular",
        "class", "class-data", "class-events", "class-method", "class-methods", "class-pool", "cleanup", "clear", "client",
        "clients", "clock", "clone", "close", "cn", "cnt", "co", "code", "collect", "color", "column", "comment", "comments",
        "commit", "common", "communication", "comparing", "component", "components", "compression", "compute", "concatenate",
        "cond", "condense", "condition", "connection", "constant", "constants", "context", "contexts", "continue", "control",
        "controls", "conv", "conversion", "convert", "copy", "corresponding", "count", "country", "cover", "cp", "create", "cs",
        "currency", "current", "cursor", "customer-function", "data", "database", "datainfo", "dataset", "date", "daylight",
        "ddl", "deallocate", "decimals", "declarations", "deep", "default", "deferred", "define", "definition", "delete",
        "deleting", "demand", "descending", "describe", "destination", "detail", "determine", "dialog", "did", "directory",
        "discarding", "display", "display-mode", "distance", "distinct", "div", "divide", "divide-corresponding", "do", "dummy",
        "duplicate", "duplicates", "duration", "during", "dynpro", "edit", "editor-call", "else", "elseif", "empty", "enabled",
        "enabling", "encoding", "end", "end-enhancement-section", "end-of-definition", "end-of-page", "end-of-selection",
        "end-test-injection", "end-test-seam", "endat", "endcase", "endcatch", "endclass", "enddo", "endenhancement", "endexec",
        "endform", "endfunction", "endian", "endif", "ending", "endinterface", "endloop", "endmethod", "endmodule", "endon",
        "endprovide", "endselect", "endtry", "endwhile", "endwith", "enhancement", "enhancement-point", "enhancement-section",
        "enhancements", "entities", "entity", "entries", "entry", "enum", "eq", "equiv", "errors", "escape", "escaping",
        "event", "events", "exact", "except", "exception", "exception-table", "exceptions", "excluding", "exec", "execute",
        "exists", "exit", "exit-command", "expanding", "explicit", "exponent", "export", "exporting", "extended", "extension",
        "extract", "fail", "failed", "features", "fetch", "field", "field-groups", "field-symbol", "field-symbols", "fields", "file",
        "fill",
        "filter", "filters", "final", "find", "first", "first-line", "fixed-point", "flush", "following", "for", "form",
        "format", "forward", "found", "frame", "frames", "free", "from", "full", "function", "function-pool", "ge", "generate",
        "get", "giving", "graph", "group", "groups", "gt", "handle", "handler", "hashed", "having", "header", "headers",
        "heading", "help-id", "help-request", "hide", "hint", "hold", "hotspot", "icon", "id", "identification", "identifier",
        "if", "ignore", "ignoring", "immediately", "implementation", "implemented", "implicit", "import", "importing", "in",
        "inactive", "incl", "include", "includes", "including", "increment", "index", "index-line", "indicators", "infotypes",
        "inheriting", "init", "initial", "initialization", "inner", "input", "insert", "instance", "instances", "intensified",
        "interface", "interface-pool", "interfaces", "internal", "intervals", "into", "inverse", "inverted-date", "is", "job",
        "join", "keep", "keeping", "kernel", "key", "keys", "keywords", "kind", "language", "last", "late", "layout", "le",
        "leading", "leave", "left", "left-justified", "legacy", "length", "let", "level", "levels", "like", "line",
        "line-count", "line-selection", "line-size", "linefeed", "lines", "link", "list", "list-processing", "listbox", "load",
        "load-of-program", "local", "locale", "lock", "locks", "log-point", "logical", "loop", "lower", "lt", "mapped",
        "mapping", "margin", "mark", "mask", "match", "matchcode", "maximum", "members", "memory", "mesh", "message",
        "message-id", "messages", "messaging", "method", "methods", "mod", "mode", "modif", "modifier", "modify", "module",
        "move", "move-corresponding", "multiply", "multiply-corresponding", "na", "name", "nametab", "native", "ne", "nested",
        "nesting", "new", "new-line", "new-page", "new-section", "next", "no-display", "no-extension", "no-gap", "no-gaps",
        "no-grouping", "no-heading", "no-scrolling", "no-sign", "no-title", "no-zero", "nodes", "non-unicode", "non-unique",
        "not", "np", "ns", "number", "object", "objects", "objmgr", "obligatory", "occurence", "occurences", "occurrence",
        "occurrences", "occurs", "of", "offset", "on", "only", "open", "option", "optional", "options", "or", "order", "others",
        "out", "outer", "output", "output-length", "overflow", "overlay", "pack", "package", "padding", "page", "parameter",
        "parameter-table", "parameters", "part", "partially", "pcre", "perform", "performing", "permissions", "pf-status",
        "places", "pool", "position", "pragmas", "preceding", "precompiled", "preferred", "preserving", "primary", "print",
        "print-control", "private", "privileged", "procedure", "process", "program", "property", "protected", "provide",
        "public", "push", "pushbutton", "put", "query", "queue-only", "queueonly", "quickinfo", "radiobutton", "raise",
        "raising", "range", "ranges", "read", "read-only", "receive", "received", "receiving", "redefinition", "reduce", "ref",
        "reference", "refresh", "regex", "reject", "renaming", "replace", "replacement", "replacing", "report", "reported",
        "request", "requested", "required", "reserve", "reset", "resolution", "respecting", "response", "restore", "result",
        "results", "resumable", "resume", "retry", "return", "returning", "right", "right-justified", "rollback", "rows",
        "rp-provide-from-last", "run", "sap", "sap-spool", "save", "saving", "scan", "screen", "scroll", "scroll-boundary",
        "scrolling", "search", "secondary", "seconds", "section", "select", "select-options", "selection", "selection-screen",
        "selection-set", "selection-sets", "selection-table", "selections", "send", "separate", "separated", "session", "set",
        "shared", "shift", "shortdump", "shortdump-id", "sign", "simple", "simulation", "single", "size", "skip", "skipping",
        "smart", "some", "sort", "sortable", "sorted", "source", "specified", "split", "spool", "spots", "sql", "stable",
        "stamp", "standard", "start-of-selection", "starting", "state", "statement", "statements", "static", "statics",
        "statusinfo", "step", "step-loop", "stop", "strlen", "structure", "structures", "style", "subkey", "submatches",
        "submit", "subroutine", "subscreen", "substring", "subtract", "subtract-corresponding", "suffix", "sum", "summary",
        "supplied", "supply", "suppress", "switch", "symbol", "syntax-check", "syntax-trace", "system-call",
        "system-exceptions", "tab", "tabbed", "table", "tables", "tableview", "tabstrip", "target", "task", "tasks", "test",
        "test-injection", "test-seam", "testing", "text", "textpool", "then", "throw", "time", "times", "title", "titlebar",
        "to", "tokens", "top-lines", "top-of-page", "trace-file", "trace-table", "trailing", "transaction", "transfer",
        "transformation", "translate", "transporting", "trmac", "truncate", "truncation", "try", "type", "type-pool",
        "type-pools", "types", "uline", "unassign", "unbounded", "under", "unicode", "union", "unique", "unit", "unix",
        "unpack", "until", "unwind", "up", "update", "upper", "user", "user-command", "using", "utf-8", "uuid", "valid",
        "validate", "value", "value-request", "values", "vary", "varying", "version", "via", "visible", "wait", "when", "where",
        "while", "window", "windows", "with", "with-heading", "with-title", "without", "word", "work", "workspace", "write",
        "xml", "xsdbool", "xstrlen", "zone",
    ]
}

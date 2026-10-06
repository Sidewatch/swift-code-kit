//
//  VerilogRules.swift
//  CodeHighlighting
//
//  The regex rule table for Verilog and SystemVerilog.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The regex rule table for Verilog and SystemVerilog: every IEEE 1800 keyword (the Verilog ones are a
/// subset), the net and variable types, the name a `class`, `extends` or `implements` introduces as a
/// type, sized literals, `$system` tasks, `` `macros ``, and `"""…"""` strings beside `"…"`. A keyword
/// before a bracket (`if (`, `case (`) stays a keyword; any other name before one is a call.
/// Later rules repaint earlier ones; strings and comments paint last.
extension RuleTables {
    static let verilog: [(String, TokenKind)] = [
        lineComment,
        blockComment,
        ("\"\"\"[\\s\\S]*?\"\"\"", .string),
        // The only string delimiter is `"`, and a string ends at its line unless a backslash continues it.
        ("\"(?:[^\"\\\\\\n]|\\\\[\\s\\S])*\"", .string),
        ("\\b([A-Za-z_]\\w*)\\s*\\(", .function),
        ("\\b(?:class|extends)[ \\t]+[A-Za-z_]\\w*|\\bimplements[ \\t]+[A-Za-z_]\\w*(?:[ \\t]*,[ \\t]*[A-Za-z_]\\w*)*", .type),
        wordTrie(
            [
                "accept_on", "alias", "always", "always_comb", "always_ff", "always_latch", "and", "assert", "assign", "assume",
                "automatic", "before", "begin", "bind", "bins", "binsof", "break", "buf", "bufif0", "bufif1", "case", "casex",
                "casez", "cell", "checker", "class", "clocking", "cmos", "config", "const", "constraint", "context", "continue",
                "cover", "covergroup", "coverpoint", "cross", "deassign", "default", "defparam", "design", "disable", "dist",
                "do", "edge", "else", "end", "endcase", "endchecker", "endclass", "endclocking", "endconfig", "endfunction",
                "endgenerate", "endgroup", "endinterface", "endmodule", "endpackage", "endprimitive", "endprogram",
                "endproperty", "endspecify", "endsequence", "endtable", "endtask", "enum", "eventually", "expect", "export",
                "extends", "extern", "final", "first_match", "for", "force", "foreach", "forever", "fork", "forkjoin",
                "function", "generate", "genvar", "global", "highz0", "highz1", "if", "iff", "ifnone", "ignore_bins",
                "illegal_bins", "implements", "implies", "import", "incdir", "include", "initial", "inout", "input", "inside",
                "instance", "interface", "intersect", "join", "join_any", "join_none", "large", "let", "liblist", "library",
                "local", "localparam", "macromodule", "matches", "medium", "modport", "module", "nand", "negedge", "nettype",
                "new", "nexttime", "nmos", "nor", "noshowcancelled", "not", "notif0", "notif1", "null", "or", "output",
                "package", "packed", "parameter", "pmos", "posedge", "primitive", "priority", "program", "property",
                "protected", "pull0", "pull1", "pulldown", "pullup", "pulsestyle_ondetect", "pulsestyle_onevent", "pure",
                "rand", "randc", "randcase", "randsequence", "rcmos", "ref", "reject_on", "release", "repeat", "restrict",
                "return", "rnmos", "rpmos", "rtran", "rtranif0", "rtranif1", "s_always", "s_eventually", "s_nexttime",
                "s_until", "s_until_with", "scalared", "sequence", "showcancelled", "small", "soft", "solve", "specify",
                "specparam", "static", "strong", "strong0", "strong1", "struct", "super", "sync_accept_on", "sync_reject_on",
                "table", "tagged", "task", "this", "throughout", "timeprecision", "timeunit", "tran", "tranif0", "tranif1",
                "type", "typedef", "union", "unique", "unique0", "until", "until_with", "untyped", "use", "vectored", "virtual",
                "wait", "wait_order", "weak", "weak0", "weak1", "while", "wildcard", "with", "within", "xnor", "xor",
            ], .keyword),
        wordTrie(
            [
                "wire", "reg", "logic", "bit", "byte", "shortint", "int", "longint", "integer", "time", "real", "realtime",
                "shortreal", "string", "event", "signed", "unsigned", "tri", "tri0", "tri1", "supply0", "supply1", "wand",
                "wor", "trireg", "triand", "trior", "uwire", "interconnect", "void", "chandle", "var",
            ], .type),
        // Sized and based literals: the quote is a base marker (`8'hFF`, `'b1`), not a string.
        ("(?:\\b\\d[\\d_]*)?'[sS]?[bBoOdDhH][0-9a-fA-F_xXzZ?]+", .number),
        ("'[01xXzZ]\\b", .number),
        ("\\b\\d[\\d_]*(?:\\.\\d[\\d_]*)?(?:[eE][+-]?\\d+)?(?:[munpf]?s)?\\b", .number),
        ("\\$[A-Za-z_]\\w*", .function),
        ("`[A-Za-z_]\\w*", .attribute),
    ]
}

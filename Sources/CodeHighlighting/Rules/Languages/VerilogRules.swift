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

/// The regex rule table for Verilog and SystemVerilog.
/// Later rules repaint earlier ones; strings and comments paint last.
extension RuleTables {
    static let verilog: [(String, TokenKind)] = [
        lineComment,
        blockComment,
        // The only string delimiter is `"`, and a string ends at its line unless a backslash continues it.
        ("\"(?:[^\"\\\\\\n]|\\\\[\\s\\S])*\"", .string),
        keywords([
            "module", "endmodule", "macromodule", "program", "endprogram", "interface", "endinterface", "package",
            "endpackage", "class", "endclass", "function", "endfunction", "task", "endtask", "begin", "end",
            "fork", "join", "join_any", "join_none", "generate", "endgenerate", "genvar", "if", "else", "case",
            "casex", "casez", "endcase", "default", "for", "foreach", "while", "do", "repeat", "forever",
            "always", "always_comb", "always_ff", "always_latch", "initial", "final", "assign", "deassign",
            "force", "release", "posedge", "negedge", "edge", "or", "and", "not", "return", "break",
            "continue", "import", "export", "typedef", "enum", "struct", "union", "packed", "parameter",
            "localparam", "defparam", "specify", "endspecify", "extends", "implements", "virtual", "static",
            "automatic", "const", "ref", "input", "output", "inout", "modport", "clocking", "endclocking",
            "constraint", "rand", "randc", "covergroup", "endgroup", "coverpoint", "property", "endproperty",
            "sequence", "endsequence", "assert", "assume", "cover", "inside", "iff", "new", "this", "super",
            "extern", "local", "protected", "pure", "unique", "unique0", "priority", "with", "wait", "disable",
            "table", "endtable", "primitive", "endprimitive", "config", "endconfig", "checker", "endchecker",
        ]),
        types([
            "wire", "reg", "logic", "bit", "byte", "shortint", "int", "longint", "integer", "time", "real",
            "realtime", "shortreal", "string", "event", "signed", "unsigned", "tri", "tri0", "tri1", "supply0",
            "supply1", "wand", "wor", "trireg", "void", "chandle", "var",
        ]),
        // Sized and based literals: the quote is a base marker (`8'hFF`, `'b1`), not a string.
        ("(?:\\b\\d[\\d_]*)?'[sS]?[bBoOdDhH][0-9a-fA-F_xXzZ?]+", .number),
        ("'[01xXzZ]\\b", .number),
        ("\\b\\d[\\d_]*(?:\\.\\d[\\d_]*)?(?:[eE][+-]?\\d+)?(?:[munpf]?s)?\\b", .number),
        ("\\$[A-Za-z_]\\w*", .function),
        ("`[A-Za-z_]\\w*", .attribute),
        ("\\b([A-Za-z_]\\w*)\\s*\\(", .function),
    ]
}

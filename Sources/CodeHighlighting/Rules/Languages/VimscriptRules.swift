//
//  VimscriptRules.swift
//  CodeHighlighting
//
//  The regex rule table for Vim script.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The regex rule table for Vim script.
/// Later rules repaint earlier ones; strings and comments paint last.
extension RuleTables {
    static let vimscript: [(String, TokenKind)] = [
        // A `"` that opens a line is a comment (`withOwnComments` adds that rule); one after a command is
        // a comment only when a space follows it and nothing closes it on the line (`" "` is a string).
        ("(?<=\\s)\"[ \\t][^\"\\n]*$", .comment),
        // Strings end on their line: `\"` escapes in the double-quoted form, `''` in the single-quoted one.
        ("\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        ("'(?:[^'\\n]|'')*'", .string),
        // Patterns are strings: `:s/pat/rep/flags` and `:g/pat/` with any delimiter after a range,
        // `catch /pat/`, `match Group /pat/`, `vimgrep /pat/`, and a `/pat/` range that opens a line.
        // The command letters (`s`, `g!`) and the flags stay code; the pattern and replacement are strings.
        (
            "([/#|])(?<=(?:^|[\\s%$'<>,.\\d*:])(?:s|substitute)[/#|])(?:(?!\\1)[^\\\\\\n]|\\\\.)*\\1(?:(?!\\1)[^\\\\\\n]|\\\\.)*\\1",
            .string
        ),
        ("([/#])(?<=(?:^|[\\s%$'<>,.\\d])(?:g|v|global|vglobal)!?[/#])(?:(?!\\1)[^\\\\\\n]|\\\\.)*\\1", .string),
        ("(?<=\\b(?:catch|vimgrep|match[ \\t]{1,8}\\w{1,60})[ \\t]{1,8})/(?:[^/\\\\\\n]|\\\\.)*/", .string),
        // A `:syntax region`'s `start=/…/`, `skip=/…/` and `end=/…/` patterns.
        ("/(?<=\\b(?:start|skip|end)=/)(?:[^/\\\\\\n]|\\\\.)*/", .string),
        ("^[ \\t]*/(?:[^/\\\\\\n]|\\\\.)*/", .string),
        // A path-like option value: `set undodir=~/.vim/undo//`, `set shell=/bin/zsh`.
        ("(?<=\\bset(?:local|global)?\\b[^\\n\"]{0,200}=)[~/][^\\s|\"]*", .string),
        keywords([
            "if", "elseif", "else", "endif", "for", "endfor", "in", "while", "endwhile", "break", "continue",
            "function", "endfunction", "def", "enddef", "return", "call", "let", "const", "unlet", "lockvar",
            "unlockvar", "set", "setlocal", "setglobal", "try", "catch", "finally", "endtry", "throw",
            "execute", "exe", "echo", "echom", "echon", "echomsg", "echoerr", "autocmd", "augroup", "au",
            "command", "syntax", "highlight", "hi", "filetype", "runtime", "source", "import", "export",
            "finish", "scriptencoding", "map", "nmap", "imap", "vmap", "xmap", "omap", "cmap", "tmap", "noremap",
            "nnoremap", "inoremap", "vnoremap", "xnoremap", "onoremap", "cnoremap", "tnoremap", "unmap",
            "abbreviate", "iabbrev", "cabbrev", "normal", "silent", "keepjumps", "keeppatterns", "abort",
            "range", "dict", "closure", "is", "isnot", "var", "final", "vim9script", "class", "endclass",
            "fold", "foldopen", "foldclose",
        ]),
        // The arguments of a `:syntax` definition.
        (
            "\\b(?:start|skip|end|oneline|contains|containedin|contained|matchgroup|nextgroup|keepend|extend|excludenl|transparent|skipwhite|skipnl|skipempty|concealends|conceal|display|fold)(?==|\\b)",
            .keyword
        ),
        constants(["v:true", "v:false", "v:null", "v:none", "true", "false", "null"]),
        ("\\b[bwtglsav]:[A-Za-z_][\\w#]*|\\bv:[a-z_]+", .variable),
        ("<[A-Za-z][A-Za-z0-9-]*(?:-[A-Za-z0-9]+)*>|<[CMSAD]-[^>]+>", .attribute),
        ("\\b0[xX][0-9a-fA-F]+\\b|\\b0[bB][01]+\\b|\\b0[oO][0-7]+\\b|\\b\\d+(\\.\\d+)?([eE][+-]?\\d+)?\\b", .number),
        ("\\b([A-Za-z_][\\w#:]*)\\(", .function),
    ]
}

//
//  CaddyfileRules.swift
//  CodeHighlighting
//
//  The regex rule table for the Caddyfile.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Caddyfile: `#` comments at a token's start, `"…"` strings, `` `…` `` raw strings (may hold `"`),
/// `<<EOF` heredocs to their closing marker, the HTTP directives as keywords where a line starts,
/// `@matcher` names, `{placeholders}` outside strings, durations and sizes (`30s`, `50mb`), status
/// classes (`2xx`), and numbers.
extension RuleTables {
    static let caddyfile: [(String, TokenKind)] = [
        ("<<([A-Za-z_]\\w*)\\n[\\s\\S]*?^[ \\t]*\\1\\b", .string),
        ("\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
        ("`[^`]*`", .string),
        (
            "^[ \\t]*(abort|acme_server|basic_auth|basicauth|bind|encode|error|file_server|forward_auth|fs|handle|handle_errors|handle_path|header|import|intercept|invoke|log|log_append|log_name|log_skip|map|method|metrics|php_fastcgi|push|redir|request_body|request_header|respond|reverse_proxy|rewrite|root|route|skip_log|templates|tls|tracing|try_files|uri|vars)(?![\\w.-])",
            .keyword
        ),
        ("@[A-Za-z_][\\w-]*", .attribute),
        ("\\{[$%]?[A-Za-z_.][\\w.:/$%-]*(?:\\[[^\\]\\n]*\\])?\\}", .variable),
        (
            "(?<![\\w.-])(?:\\d+(?:\\.\\d+)?(?:ns|us|µs|ms|s|m|h|d|[kKmMgGtT][iI]?[bB])|[1-5]xx|\\d+(?:\\.\\d+)?)(?![\\w.-])",
            .number
        ),
    ]
}

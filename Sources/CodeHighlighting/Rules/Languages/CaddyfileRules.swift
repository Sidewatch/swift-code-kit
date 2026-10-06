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

/// Caddyfile: `#` comments at a token's start, `"…"` strings (a `{placeholder}` inside one stays a
/// variable), `` `…` `` raw strings (may hold `"`), `<<EOF` heredocs to their closing marker, the HTTP
/// directives as keywords where a line starts, `@matcher` names, `{placeholders}`, durations and sizes
/// (`30s`, `50mb`), status classes (`2xx`), and numbers.
extension RuleTables {
    static let caddyfile: [(String, TokenKind)] =
        [
            ("<<([A-Za-z_]\\w*)\\n[\\s\\S]*?^[ \\t]*\\1\\b", .string),
            ("`[^`]*`", .string),
        ]
        // Caddy replaces a placeholder inside a quoted argument too (`"hello from {host}"`).
        + interpolatedStringPieces(
            open: "\"", close: "\"", literal: "[^\"\\\\{\\n]|\\\\[\\s\\S]|\\{(?!\(caddyPlaceholderBody))",
            hole: "\\{" + caddyPlaceholderBody, holeOpen: "\\{[$%]?[A-Za-z_.]", holeClose: "\\}", multiline: true,
            skip: ["<<([A-Za-z_]\\w*)\\n[\\s\\S]*?\\n[ \\t]*\\1\\b", "`[^`]*`", "#(?<![^ \\t\\n]#)[^\\n]*"])
        + [
            (
                "^[ \\t]*(abort|acme_server|basic_auth|basicauth|bind|encode|error|file_server|forward_auth|fs|handle|handle_errors|handle_path|header|import|intercept|invoke|log|log_append|log_name|log_skip|map|method|metrics|php_fastcgi|push|redir|request_body|request_header|respond|reverse_proxy|rewrite|root|route|skip_log|templates|tls|tracing|try_files|uri|vars)(?![\\w.-])",
                .keyword
            ),
            ("@[A-Za-z_][\\w-]*", .attribute),
            ("\\{" + caddyPlaceholderBody, .variable),
            (
                "(?<![\\w.-])(?:\\d+(?:\\.\\d+)?(?:ns|us|µs|ms|s|m|h|d|[kKmMgGtT][iI]?[bB])|[1-5]xx|\\d+(?:\\.\\d+)?)(?![\\w.-])",
                .number
            ),
        ]

    /// A placeholder after its `{`: `{host}`, `{http.request.uri.path}`, `{$ENV}`, `{%ENV}`, `{args[0]}`.
    private static let caddyPlaceholderBody = "[$%]?[A-Za-z_.][\\w.:/$%-]*(?:\\[[^\\]\\n]*\\])?\\}"
}

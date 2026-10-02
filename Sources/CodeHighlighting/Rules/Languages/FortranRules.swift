//
//  FortranRules.swift
//  CodeHighlighting
//
//  The regex rule table for Fortran.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Fortran (free form, with fixed-form `C` comment lines tolerated): `!` comments, the
/// case-insensitive statement words, intrinsic types, `%` components, `1.0d0` literals. A fixed-form
/// comment is `*`, or a `C` that no letter follows, in the first column: `contains` there is the
/// statement. A call's name is painted before the words, so `if (` and `intent(` stay keywords.
extension RuleTables {
    static let fortran: [(String, TokenKind)] = [
        ("!.*$", .comment),
        ("^(?:\\*|[cC](?![A-Za-z0-9_])).*$", .comment),
        doubleQuotedPlain,
        singleQuotedPlain,
        ("\\b[a-zA-Z_]\\w*(?=\\s*\\()", .function),
        (
            "(?i)\\b(program|module|submodule|contains|subroutine|function|result|end|implicit|none|intent|in|out|inout|do|concurrent|enddo|if|then|else|elseif|endif|call|print|write|read|allocate|deallocate|use|type|pure|elemental|recursive|parameter|dimension|allocatable|select|case|while|return|stop|only|private|public|interface|procedure|abstract|extends|class|where|elsewhere|forall|cycle|exit|goto|continue|format|open|close|inquire|namelist|data|save|target|pointer|optional|value|volatile|import|block|associate|enum|enumerator|sequence|bind|kind|len|intrinsic|external|sync|all|images|memory|critical|error|common|equivalence|entry|deferred|pass|nopass|generic|final|non_overridable|non_intrinsic|protected|contiguous|asynchronous|rewind|backspace|endfile|flush|nullify|go\\s*to|endprogram|endmodule|endsubroutine|endfunction|endtype|endinterface|endselect|endassociate|endblock|endwhere|endforall|endenum|impure|non_recursive|simple|block\\s+data|is|default)\\b",
            .keyword
        ),
        ("(?i)\\b(integer|real|double\\s+precision|double\\s+complex|complex|character|logical)\\b", .type),
        ("\\b\\d+(\\.\\d*)?([dDeE][+-]?\\d+)?(_\\w+)?\\b", .number),
        (
            "(?i)\\b(sum|size|abs|sqrt|exp|log|sin|cos|tan|min|max|mod|nint|int|real|dble|trim|len|allocated|present|associated|huge|tiny|epsilon|matmul|dot_product|transpose|reshape|maxval|minval|count|any|all)\\b(?=\\s*\\()",
            .function
        ),
        ("%\\w+", .property),
    ]
}

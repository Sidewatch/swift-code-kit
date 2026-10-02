[
  (string)
  (raw_string)
  (heredoc_body)
  (heredoc_start)
] @string

(command_name) @function

(variable_name) @property

[
  "case"
  "do"
  "done"
  "elif"
  "else"
  "esac"
  "export"
  "fi"
  "for"
  "function"
  "if"
  "in"
  "select"
  "then"
  "unset"
  "until"
  "while"
] @keyword

(comment) @comment

(function_definition name: (word) @function)

(file_descriptor) @number

[
  (command_substitution)
  (process_substitution)
  (expansion)
]@embedded

[
  "$"
  "&&"
  ">"
  ">>"
  "<"
  "|"
] @operator

(
  (command (_) @constant)
  (#match? @constant "^-")
)

; Sidewatch additions (4 Sep 2026): tokens the grammar defines but the upstream query left plain.
; Appended last on purpose — the highlighter lets the highest pattern index win.
[ "local" "declare" "readonly" "typeset" "export" "unset" "unsetenv" ] @function.builtin
; The closing delimiter of a heredoc, `$'…'` (ANSI-C quoting) and `$"…"` (translated) strings are strings like
; the rest; literal numbers are numbers.
[ (heredoc_end) (ansi_c_string) (translated_string) ] @string
(number) @number
; `return`, `break`, `continue` and `exit` are builtins the grammar parses as command names; they are flow keywords.
((command_name (word) @keyword) (#match? @keyword "^(return|break|continue|exit)$"))

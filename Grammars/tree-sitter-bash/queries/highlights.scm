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
; The operators of a parameter expansion (`${x:-…}`, `${#x}`, `${!x}`, `${x%%.*}`, `${x//a/b}`, `${x@Q}`) and an
; all-elements subscript (`${a[@]}`, `${a[*]}`) are code inside a double-quoted string, as VS Code scopes them.
(expansion
  operator: _ @plain)
(subscript
  index: (word) @plain
  (#match? @plain "^[@*]$"))
; Backtick command substitution: the backticks are string punctuation, as VS Code paints them.
[ "`" "``" ] @string
; A word that opens with a backslash escape (`\$`, `\'`, `\"`, `\\`, `\#…`) is quoted text.
((word) @string
  (#match? @string "^\\\\"))
; A decimal word (`3.14159`) is a number.
((word) @number
  (#match? @number "^[0-9]+\\.[0-9]+$"))
; A quoted part of a dash-led argument (`-"$pid"`) stays a string under the option paint above.
(command
  argument: (concatenation
    (string) @string))
(command
  argument: (concatenation
    (string
      [(simple_expansion) (expansion)] @plain)))
(command
  argument: (concatenation
    (string
      [(simple_expansion (variable_name) @property) (expansion (variable_name) @property)])))
; The glob pattern of a removal or substitution (`${x%/*}`, `${x##*/}`), a positional-list subject (`${@:2}`) and
; arithmetic operators inside a string (`"$((n * 2))"`) are code too.
(expansion
  [(regex) (special_variable_name)] @plain)
(binary_expression
  operator: _ @plain)

(identifier) @variable

; Sidewatch: upstream's `((identifier) @function.method (#is-not? local))` needs a locals pass this highlighter
; does not run, so every identifier (locals and parameters included) painted as a method call. A bare
; identifier is a plain name here; calls are recognised by the `call` patterns below.

[
  "alias"
  "and"
  "begin"
  "break"
  "case"
  "class"
  "def"
  "do"
  "else"
  "elsif"
  "end"
  "ensure"
  "for"
  "if"
  "in"
  "module"
  "next"
  "or"
  "rescue"
  "retry"
  "return"
  "then"
  "unless"
  "until"
  "when"
  "while"
  "yield"
] @keyword

((identifier) @keyword
 (#match? @keyword "^(private|protected|public)$"))

(constant) @constructor

; Function calls

"defined?" @function.method.builtin

(call
  method: [(identifier) (constant)] @function.method)

((identifier) @function.method.builtin
 (#eq? @function.method.builtin "require"))

; Function definitions

(alias (identifier) @function.method)
(setter (identifier) @function.method)
(method name: [(identifier) (constant)] @function.method)
(singleton_method name: [(identifier) (constant)] @function.method)

; Identifiers

[
  (class_variable)
  (instance_variable)
] @property

((identifier) @constant.builtin
 (#match? @constant.builtin "^__(FILE|LINE|ENCODING)__$"))

(file) @constant.builtin
(line) @constant.builtin
(encoding) @constant.builtin

(hash_splat_nil
  "**" @operator) @constant.builtin

((constant) @constant
 (#match? @constant "^[A-Z\\d_]+$"))

[
  (self)
  (super)
] @variable.builtin

(block_parameter (identifier) @variable.parameter)
(block_parameters (identifier) @variable.parameter)
(destructured_parameter (identifier) @variable.parameter)
(hash_splat_parameter (identifier) @variable.parameter)
(lambda_parameters (identifier) @variable.parameter)
(method_parameters (identifier) @variable.parameter)
(splat_parameter (identifier) @variable.parameter)

(keyword_parameter name: (identifier) @variable.parameter)
(optional_parameter name: (identifier) @variable.parameter)

; Literals

[
  (string)
  (subshell)
  (heredoc_body)
  (heredoc_beginning)
] @string
; Sidewatch: a `%W[…]` word is its text, not the whole node, so a word that is only `#{expr}` stays code.
(bare_string [(string_content) (escape_sequence)] @string)

[
  (simple_symbol)
  (delimited_symbol)
  (hash_key_symbol)
  (bare_symbol)
] @string.special.symbol

(regex) @string.special.regex
(escape_sequence) @escape

[
  (integer)
  (float)
] @number

[
  (nil)
  (true)
  (false)
] @constant.builtin

(interpolation
  "#{" @punctuation.special
  "}" @punctuation.special) @embedded

(comment) @comment

; Operators

[
"="
"=>"
"->"
] @operator

[
  ","
  ";"
  "."
] @punctuation.delimiter

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
  "%w("
  "%i("
] @punctuation.bracket

; Sidewatch additions (4 Sep 2026): tokens the grammar defines but the upstream query left plain.
; Appended last on purpose — the highlighter lets the highest pattern index win.
[ "not" "and" "or" ] @keyword.operator
[ "undef" "BEGIN" "END" "alias" "defined?" "redo" "retry" ] @keyword
; `super` is a keyword, not a variable; a `%w[…]` / `%i[…]` literal's delimiters belong to the literal.
(super) @keyword
(string_array ["%w(" ")"] @string)
(symbol_array ["%i(" ")"] @string.special.symbol)

; A symbol is a constant (VS Code's `constant.other.symbol`), not a string: `:name`, `name:`, `%i[a b]`.
[
  (simple_symbol)
  (delimited_symbol)
  (hash_key_symbol)
  (bare_symbol)
] @constant
(symbol_array ["%i(" ")"] @constant)

; Operator and setter method names are the method's name: `def <=>(other)`, `def []=(k, v)`, `def name=(v)`.
(method name: [(operator) (setter)] @function.method)
(singleton_method name: [(operator) (setter)] @function.method)

; Kernel and Module methods that read as keywords when called without a receiver (`include Comparable`,
; `attr_reader :name`, `raise Error`, `loop do`), as both VS Code (`keyword.other.special-method`) and
; Pygments class them.
((identifier) @keyword
 (#any-of? @keyword "include" "extend" "prepend" "attr_reader" "attr_writer" "attr_accessor" "attr" "private" "protected" "public" "module_function" "raise" "fail" "loop" "catch" "throw" "new"))
(call
  !receiver
  method: (identifier) @keyword
  (#any-of? @keyword "include" "extend" "prepend" "attr_reader" "attr_writer" "attr_accessor" "attr" "private" "protected" "public" "module_function" "raise" "fail" "loop" "catch" "throw" "new"))

; An interpolation is code inside the string, symbol or regex: `#{expr}`.
(interpolation) @code

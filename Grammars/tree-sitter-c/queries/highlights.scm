(identifier) @variable

((identifier) @constant
 (#match? @constant "^[A-Z][A-Z\\d_]*$"))

"break" @keyword
"case" @keyword
"const" @keyword
"continue" @keyword
"default" @keyword
"do" @keyword
"else" @keyword
"enum" @keyword
"extern" @keyword
"for" @keyword
"if" @keyword
"inline" @keyword
"return" @keyword
"sizeof" @keyword
"static" @keyword
"struct" @keyword
"switch" @keyword
"typedef" @keyword
"union" @keyword
"volatile" @keyword
"while" @keyword

"#define" @keyword
"#elif" @keyword
"#else" @keyword
"#endif" @keyword
"#if" @keyword
"#ifdef" @keyword
"#ifndef" @keyword
"#include" @keyword
(preproc_directive) @keyword

"--" @operator
"-" @operator
"-=" @operator
"->" @operator
"=" @operator
"!=" @operator
"*" @operator
"&" @operator
"&&" @operator
"+" @operator
"++" @operator
"+=" @operator
"<" @operator
"==" @operator
">" @operator
"||" @operator

"." @delimiter
";" @delimiter

(string_literal) @string
(system_lib_string) @string

(null) @constant
(number_literal) @number
; A character literal is a quoted literal, coloured with the strings.
(char_literal) @string

(field_identifier) @property
(statement_identifier) @label
(type_identifier) @type
(primitive_type) @type
(sized_type_specifier) @type

(call_expression
  function: (identifier) @function)
(call_expression
  function: (field_expression
    field: (field_identifier) @function))
(function_declarator
  declarator: (identifier) @function)
(preproc_function_def
  name: (identifier) @function.special)

(comment) @comment

; Sidewatch additions (4 Sep 2026): tokens the grammar defines but the upstream query left plain.
; This file is also PREPENDED to the C++ query, so only tokens both grammars define may appear here.
; Appended last on purpose — the highlighter lets the highest pattern index win.
[ "goto" "register" "extern" "static" "inline" "volatile" "const" "signed" "unsigned" "restrict" "_Atomic" "_Noreturn" "typedef" "sizeof" "_BitInt" "_Complex" "_Imaginary" "_Thread_local" "thread_local" "_Pragma" ] @keyword
[ (true) (false) ] @boolean

; A primitive type name the grammar reads as an identifier (a macro argument: `va_arg(args, int)`) is still
; the type keyword; `auto(n)` is C++23's decay-copy, not a call of something named `auto`.
(argument_list
  (identifier) @type.builtin
  (#any-of? @type.builtin "char" "short" "int" "long" "float" "double" "void" "signed" "unsigned" "bool" "_Bool"))
(call_expression function: (identifier) @keyword (#eq? @keyword "auto"))

; `_BitInt(8)`: the width is a number inside the type.
(bit_int_specifier (number_literal) @number)

; GNU inline assembly and the Microsoft calling-convention and pointer modifiers are keywords.
(gnu_asm_expression ["asm" "__asm__" "__asm"] @keyword)
(ms_call_modifier) @keyword
(ms_pointer_modifier) @keyword
(ms_based_modifier "__based" @keyword)

; `#if 0 … #endif` is code switched off: a comment, as VS Code paints it. The directives themselves, the
; condition and an `#else` branch keep their own colours (`@code` spans inside the comment).
((preproc_if
  "#if" @code
  condition: (number_literal) @_zero @code
  alternative: (_)? @code
  "#endif" @code) @comment
 (#eq? @_zero "0"))

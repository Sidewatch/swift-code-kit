[
  (php_tag)
  (php_end_tag)
] @tag

; Keywords

[
  "and"
  "as"
  "break"
  "case"
  "catch"
  "class"
  "clone"
  "const"
  "continue"
  "declare"
  "default"
  "do"
  "echo"
  "else"
  "elseif"
  "enddeclare"
  "endfor"
  "endforeach"
  "endif"
  "endswitch"
  "endwhile"
  "enum"
  "exit"
  "extends"
  "finally"
  "fn"
  "for"
  "foreach"
  "function"
  "global"
  "goto"
  "if"
  "implements"
  "include"
  "include_once"
  "instanceof"
  "insteadof"
  "interface"
  "match"
  "namespace"
  "new"
  "or"
  "print"
  "require"
  "require_once"
  "return"
  "switch"
  "throw"
  "trait"
  "try"
  "use"
  "while"
  "xor"
  "yield"
  "yield from"
  "unset"
  (abstract_modifier)
  (final_modifier)
  (readonly_modifier)
  (static_modifier)
  (visibility_modifier)
] @keyword

(function_static_declaration "static" @keyword)

; Namespace

(namespace_definition
  name: (namespace_name
    (name) @module))

(namespace_name
  (name) @module)

(namespace_use_clause
  [
    (name) @type
    (qualified_name
      (name) @type)
    alias: (name) @type
  ])

(namespace_use_clause
  type: "function"
  [
    (name) @function
    (qualified_name
      (name) @function)
    alias: (name) @function
  ])

(namespace_use_clause
  type: "const"
  [
    (name) @constant
    (qualified_name
      (name) @constant)
    alias: (name) @constant
  ])

(relative_name "namespace" @module.builtin)

; Variables

(relative_scope) @variable.builtin

(variable_name) @variable

(method_declaration name: (name) @constructor
  (#eq? @constructor "__construct"))

(object_creation_expression [
  (name) @constructor
  (qualified_name (name) @constructor)
  (relative_name (name) @constructor)
])

((name) @constant
 (#match? @constant "^_?[A-Z][A-Z\\d_]+$"))
((name) @constant.builtin
 (#match? @constant.builtin "^__[A-Z][A-Z\d_]+__$"))
(const_declaration (const_element (name) @constant))

; Types

(primitive_type) @type.builtin
(cast_type) @type.builtin
(named_type [
  (name) @type
  (qualified_name (name) @type)
  (relative_name (name) @type)
]) @type
(named_type (name) @type.builtin
  (#any-of? @type.builtin "static" "self"))

(scoped_call_expression
  scope: [
    (name) @type
    (qualified_name (name) @type)
    (relative_name (name) @type)
  ])

; The class before `::` in constant/static-property access — `Limits::MAX_BATCH`,
; `Config::$instance`. Only calls were covered, leaving these scopes unpainted.
; The constant-access node has NO fields and both sides are `name` children, so
; the leading anchor (`.`) pins the capture to the scope side only.
(class_constant_access_expression . [
  (name) @type
  (qualified_name (name) @type)
  (relative_name (name) @type)
])

(scoped_property_access_expression
  scope: [
    (name) @type
    (qualified_name (name) @type)
    (relative_name (name) @type)
  ])

; Class-like names where they are declared or named outside a type position —
; `class Foo extends Bar implements Baz`, interfaces, traits, enums, a trait's
; `use` in a class body, `instanceof Foo`. Upstream has no pattern for any of
; them, so they drew in the plain-name colour while the same name as a
; parameter type drew type-coloured; every other grammar here paints a
; declared class as a type.
(class_declaration name: (name) @type)
(interface_declaration name: (name) @type)
(trait_declaration name: (name) @type)
(enum_declaration name: (name) @type)

(base_clause [
  (name) @type
  (qualified_name (name) @type)
  (relative_name (name) @type)
])

(class_interface_clause [
  (name) @type
  (qualified_name (name) @type)
  (relative_name (name) @type)
])

(use_declaration [
  (name) @type
  (qualified_name (name) @type)
  (relative_name (name) @type)
])

(binary_expression
  operator: "instanceof"
  right: [
    (name) @type
    (qualified_name (name) @type)
    (relative_name (name) @type)
  ])

; Functions

(array_creation_expression "array" @function.builtin)
(list_literal "list" @function.builtin)
(exit_statement "exit" @function.builtin "(")

; `exit` and `die` with no parentheses — `defined( 'ABSPATH' ) || exit;` — parse
; as a bare name inside an expression, and `die` is never the keyword. Paint
; them as `exit( 1 )` above already is. PHP names are case-insensitive.
((name) @function.builtin
 (#match? @function.builtin "^(?i:exit|die)$"))

(method_declaration
  name: (name) @function.method)

(function_call_expression
  function: [
    (qualified_name (name))
    (relative_name (name))
    (name)
  ] @function)

(scoped_call_expression
  name: (name) @function)

(member_call_expression
  name: (name) @function.method)

(function_definition
  name: (name) @function)

; Member

(property_element
  (variable_name) @property)

(member_access_expression
  name: (variable_name (name)) @property)
(member_access_expression
  name: (name) @property)

; Basic tokens
[
  (string)
  (string_content)
  (encapsed_string)
  (heredoc)
  (heredoc_body)
  (nowdoc)
  (nowdoc_body)
] @string
(boolean) @constant.builtin
(null) @constant.builtin
(integer) @number
(float) @number
(comment) @comment

((name) @variable.builtin
 (#eq? @variable.builtin "this"))

"$" @operator

; PhpStorm-style receded namespace prefixes — LAST so these outrank the
; @module coloring of the same segments (later patternIndex wins). The final
; segment of a qualified name keeps its own capture (@type/@function/@constructor);
; everything before it, separators included, recedes.
(qualified_name prefix: (namespace_name) @namespace.prefix)
(qualified_name prefix: "\\" @namespace.prefix)
(relative_name prefix: (namespace_name) @namespace.prefix)
(relative_name prefix: "\\" @namespace.prefix)

; Attributes — #[AllowDynamicProperties], #[Deprecated("x")], #[\Ns\Attr] — wear the attribute colour, as
; annotations do in every language (Swift's @MainActor, Java's @Override).
(attribute [(name) (qualified_name) (relative_name)] @attribute)
(attribute_group "#[" @punctuation.bracket "]" @punctuation.bracket)

; Group use — `use Ns\Sub\{A, B};` (PHP 7 braced imports). Here the prefix is a
; BARE (namespace_name) child of the declaration plus the "\" before the brace,
; not a qualified_name prefix field, so none of the four patterns above reached
; it: the prefix drew type-colored and the separators drew as plain text while
; the identical path in an unbraced `use` receded (David, 17 Sep 2026).
(namespace_use_declaration
  (namespace_name) @namespace.prefix
  "\\" @namespace.prefix
  body: (namespace_use_group))

; …and the braced clauses take their colour from the declaration's `function`/
; `const` keyword, which sits on the DECLARATION in this form (the unbraced
; patterns near the top read it off each clause), so `use function Ns\{ a, b };`
; painted its imports type-colored instead of function-colored.
(namespace_use_declaration
  type: "function"
  body: (namespace_use_group
    (namespace_use_clause
      [
        (name) @function
        (qualified_name (name) @function)
        alias: (name) @function
      ])))

(namespace_use_declaration
  type: "const"
  body: (namespace_use_group
    (namespace_use_clause
      [
        (name) @constant
        (qualified_name (name) @constant)
        alias: (name) @constant
      ])))

; `self::`, `parent::`, `static::` are keywords, as in VS Code (`storage.type`); `var $x` too.
(relative_scope) @keyword
(var_modifier) @keyword

; A shell command in backticks is a string like the others.
(shell_command_expression) @string

; The variables and expressions interpolated into a string, heredoc or shell command are code
; (`"$obj->prop"`, `"{$list['b'][0]}"`); their text and escapes keep the string colour.
(encapsed_string (_) @code)
(heredoc_body (_) @code)
(shell_command_expression (_) @code)
(escape_sequence) @string

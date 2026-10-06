(comment) @comment

(tag_name) @tag
(nesting_selector) @tag
(universal_selector) @tag

"~" @operator
">" @operator
"+" @operator
"-" @operator
"*" @operator
"/" @operator
"=" @operator
"^=" @operator
"|=" @operator
"~=" @operator
"$=" @operator
"*=" @operator
"<" @operator
"<=" @operator
">=" @operator

"and" @operator
"or" @operator
"not" @operator
"only" @operator

(attribute_selector (plain_value) @string)

((property_name) @variable
 (#match? @variable "^--"))
((plain_value) @variable
 (#match? @variable "^--"))

(class_name) @property
(id_name) @property
(namespace_name) @property
(property_name) @property
(feature_name) @property
(layer_name) @property
(container_name) @property
; Sidewatch: selectors that name a markup attribute or state are `@tag.attribute` (the property colour, as
; VS Code scopes them entity.other.attribute-name); `@attribute` is for annotations.
(page_selector) @tag.attribute

(pseudo_element_selector (tag_name) @tag.attribute)
(pseudo_class_selector (class_name) @tag.attribute)
(attribute_name) @tag.attribute

(function_name) @function

"@media" @keyword
"@import" @keyword
"@charset" @keyword
"@namespace" @keyword
"@supports" @keyword
"@keyframes" @keyword
"@container" @keyword
"@layer" @keyword
"@page" @keyword
"@function" @keyword
"@scope" @keyword
"returns" @keyword
(attribute_flag) @keyword
(at_keyword) @keyword
(to) @keyword
(from) @keyword
(important) @keyword

(string_value) @string
(url_call (arguments (plain_value) @string))
(color_value) @string.special

(integer_value) @number
(float_value) @number
(unit) @type

[
  "#"
  ","
  "."
  ":"
  "::"
  ";"
] @punctuation.delimiter

[
  "{"
  ")"
  "("
  "}"
] @punctuation.bracket

; Sidewatch: a hex colour is a constant (VS Code's constant.other.color), and an unquoted `url()` argument is a
; parameter, not a string, as VS Code scopes it.
(color_value) @number
(url_call
  (arguments
    (plain_value) @plain))
; An `an+b` selector argument (`:nth-child(2n + 1)`) is a number.
(pseudo_class_selector
  (arguments
    (plain_value) @number
    (#match? @number "^[-+]?[0-9]*n( *[-+] *[0-9]+)?$")))

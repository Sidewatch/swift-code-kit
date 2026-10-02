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
(page_selector) @attribute

(pseudo_element_selector (tag_name) @attribute)
(pseudo_class_selector (class_name) @attribute)
(attribute_name) @attribute

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

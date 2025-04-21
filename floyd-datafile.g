%whitespace  = ws

%externs     = _consume_trailing

%comment     = ('#'|'//') ^eol
             | '/*' ^.'*/'

%tokens      = number | string | bare_word | ws | eol

grammar      = value (?{_consume_trailing} end)     -> $1
             | member+ (?{_consume_trailing} end)   -> $1

ws           = [ \n\r\t]+

eol          = '\r\n' | '\r' | '\n'

value        = 'true'                               -> ['true', null]
             | 'false'                              -> ['false', null]
             | 'null'                               -> ['null', null]
             | <number>                             -> ['number', $1]
             | string                               -> $1
             | string_list                          -> ['string_list', $1]
             | array                                -> ['array', $1]
             | object                               -> ['object', $1]
             | bare_word                            -> $1

number       = ('-'|'+')? int frac? exp?
             | '0b' bin ((bin | '_')* bin)?
             | '0o' oct ((oct | '_')* oct)?
             | '0x' hex ((hex | '_')* hex)?
             | '0X' hex ((hex | '_')* hex)?

int          = '0'
             | nonzerodigit digit_sep

digit_sep    = ((digit | '_')* digit)?

digit        = '0' .. '9'

nonzerodigit = '1' .. '9'

frac         = '.' digit_sep

exp          = ('e'|'E') ('+'|'-')? digit_sep

bin          = '0' | '1'

oct          = '0'..'7'

hex          = '0' .. '9' | 'a' .. 'f' | 'A' .. 'F'

string_list  = '(' string (','? string)* ')'           -> cons($2, $3)

string       = string_tag str                          -> ['string', [$1, $2]]
             | raw_tag raw_str                         -> ['string', [$1, $2]]
             | bare_word                               -> ['string', ['', $1]]

bare_word    = </[^\s\[\]\(\)\{\}:'"`]+/>

string_tag   = 'd'
             |                                         -> ''

str          = tsquote tsqchar* tsquote                -> cat($2)
             | tdquote tdqchar* tdquote                -> cat($2)
             | tbquote tbqchar* tbquote                -> cat($2)
             | squote sqchar* squote                   -> cat($2)
             | dquote dqchar* dquote                   -> cat($2)
             | bquote bqchar* bquote                   -> cat($2)
             | "L'" '-'*:l "'"
               (<bslash squote> | ~("'" ={l} "'"))*:cs
               "'" ={l} "'"                            -> cat(cs)

tsquote      = "'''"

tsqchar      = <bslash squote>
             | ^tsquote

tbquote      = "```"

tdquote      = '"""'

tdqchar      = <bslash dquote>
             | ^tdquote

tbqchar      = <bslash bquote>
             | ^tsquote

squote       = "'"

dquote       = '"'

bquote       = '`'

sqchar       = <bslash squote>
             | ^squote

dqchar       = <bslash dquote>
             | ^dquote

bqchar       = <bslash bquote>
             | ^bquote

raw_tag      = 'r' string_tag                          -> cat($1, $2)
             | string_tag 'r'                          -> cat($2, $1)

raw_str      = tsquote ^tsquote tsquote                -> cat($2)
             | tdquote ^tdquote tdquote                -> cat($2)
             | tbquote ^tbquote tbquote                -> cat($2)
             | squote ^squote squote                   -> cat($2)
             | dquote ^dquote dquote                   -> cat($2)
             | bquote ^bquote bquote                   -> cat($2)

bslash       = '\\'

// Note: the parser actually stores the raw strings in the AST,
// and so the `escape` production isn't actually used, but this
// is here for reference. Theoretically we could extend the parser to
// call parse(`escape`) to decode the string instead of doing it by hand.

escape       = 'b'                                      -> '\b'
             | 'f'                                      -> '\f'
             | 'n'                                      -> '\n'
             | 'r'                                      -> '\r'
             | 't'                                      -> '\t'
             | 'v'                                      -> '\v'
             | squote
             | dquote
             | bquote
             | bslash
             | oct_escape
             | hex_escape
             | uni_escape

oct_escape   = ('0'..'7'){1,3}                          -> otou(cat($1))

hex_escape   = 'x' hex{2}                               -> xtou(cat($2))

uni_escape   = 'u' hex{4}                               -> xtou(cat($2))
             | 'U' hex{8}                               -> xtou(cat($2))

array        = '[' value? (','? value)* ']'             -> concat($2, $3)

object       = '{' member? (','? member)* '}'           -> concat($2, $3)

member       = key ':' value                            -> [$1, $3]

key          = string
             | string_list
             | ~('true' | 'false' | 'null' | number) bare_word

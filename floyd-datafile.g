%whitespace  = [ \n\r\t]+

%externs     = _consume_trailing

%comment     = ('#'|'//') ^eol*
             | '/*' ^.'*/'

%tokens      = number | string | bare_word | eol

grammar      = value _filler (?{_consume_trailing} end)   -> $1
             | member+ _filler (?{_consume_trailing} end) -> ['object', '', $1]

eol          = '\r\n' | '\r' | '\n'

value        = 'true'                               -> ['true', '', null]
             | 'false'                              -> ['false', '', null]
             | 'null'                               -> ['null', '', null]
             | <number>                             -> ['number', '', $1]
             | array
             | object
             | string

number       = ('-'|'+')? int frac? exp?
             | '0b' bin ((bin | '_')* bin)?
             | '0o' oct ((oct | '_')* oct)?
             | '0x' hex ((hex | '_')* hex)?

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

string       = string_tag str                       -> ['string', $1, $2]
             | string_list
             | bare_word                            -> ['string', '', $1]

string_list  = string_tag '(' string (','? string)* ')'
                 -> ['string_list', $1, scons($3, $4)]

string_tag   = ('d' | 'r' | 'dr' | 'rd' | tag) ~(_whitespace | _comment)
                 -> $1

tag          = bare_word                               -> $1[2]
             |                                         -> ''

// Anything that isn't whitespace or one of the punctuation symbols
// used elsewhere in the grammar.
bare_word    = ~('true' | 'false' | 'null' | number)
               </[^\s\[\]\(\)\{\}:,\/#'"`]+/>

str          = tsquote tsqchar* tsquote                -> cat($2)
             | tdquote tdqchar* tdquote                -> cat($2)
             | tbquote tbqchar* tbquote                -> cat($2)
             | squote sqchar* squote                   -> cat($2)
             | dquote dqchar* dquote                   -> cat($2)
             | bquote bqchar* bquote                   -> cat($2)
             | "L'" '-'+:l "'"
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

array        = array_tag '[' value? (','? value)* ']'
                 -> ['array', $1, concat($3, $4)]

array_tag    = tag ~(_whitespace | _comment)            -> $1

object       = object_tag '{' member? (','? member)* '}'
                -> ['object', $1, concat($3, $4)]

object_tag   = tag ~(_whitespace | _comment)            -> $1

member       = key ':' value                            -> [$1, $3]

key          = ~('true' | 'false' | 'null' | number) string

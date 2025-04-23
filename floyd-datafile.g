%whitespace  = [ \n\r\t]+

%comment     = ('#'|'//') ^eol*
             | '/*' ^.'*/'

%tokens      = number | str | bare_word | eol

%externs     = _consume_trailing

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

tag          = bare_word
             |                                         -> ''

bare_word    = ~('true' | 'false' | 'null' | number)
               <(^(punct | _whitespace))+>

str          = tsq (~tsq bchar)* tsq                -> cat($2)
             | tdq (~tdq bchar)* tdq                -> cat($2)
             | tbq (~tbq bchar)* tbq                -> cat($2)
             | sq (~sq bchar)* sq                   -> cat($2)
             | dq (~dq bchar)* dq                   -> cat($2)
             | bq (~bq bchar)* bq                   -> cat($2)
             | 'L' <sq '='+ sq>:lq (~(={lq}) bchar)*:cs ={lq} -> cat(cs)

punct        = lstart | '[' | ']' | [(){}:,/#'"`]

lstart       = <'L' sq '='+ sq>

sq           = "'"

dq           = '"'

bq           = "`"

tsq          = "'''"

tbq          = "```"

tdq          = '"""'

bchar        = <bslash (sq | dq | bq)> | any

bslash       = '\\'

array        = array_tag '[' value? (','? value)* ']'
                 -> ['array', $1, concat($3, $4)]

array_tag    = tag ~(_whitespace | _comment)            -> $1

object       = object_tag '{' member? (','? member)* '}'
                -> ['object', $1, concat($3, $4)]

object_tag   = tag ~(_whitespace | _comment)            -> $1

member       = key ':' value                            -> [$1, $3]

key          = ~('true' | 'false' | 'null' | number) string

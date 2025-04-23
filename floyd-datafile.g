%whitespace  = [ \n\r\t]+

%comment     = ('#'|'//') ^eol*
             | '/*' ^.'*/'

%tokens      = number | str | raw_str | bare_word | eol

%externs     = _consume_trailing

grammar      = value _filler trailing?                -> $1
             | member+ _filler trailing?              -> ['object', '', $1]

trailing     = ?{_consume_trailing} end

eol          = '\r\n' | '\r' | '\n'

value        = 'true'                                 -> ['true', '', null]
             | 'false'                                -> ['false', '', null]
             | 'null'                                 -> ['null', '', null]
             | <number>                               -> ['number', '', $1]
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

digit        = [0-9]

nonzerodigit = [1-9]

frac         = '.' digit_sep

exp          = ('e'|'E') ('+'|'-')? digit_sep

bin          = [01]

oct          = [0-7]

hex          = [0-9a-fA-F]

string       = raw_str_tag raw_str                    -> ['string', $1, $2]
             | string_tag str                         -> ['string', $1, $2]
             | string_list
             | bare_word                              -> ['string', '', $1]

string_list  = string_tag
               '(' string (','? string)* ')'          -> ['string_list', $1,
                                                          scons($3, $4)]
raw_str_tag  = ('r' | 'rd' | 'dr')
                 ~(_whitespace | _comment)            -> $1

string_tag   = ('d' | tag) ~(_whitespace | _comment)  -> $1

tag          = bare_word
             |                                        -> ''

bare_word    = ~('true' | 'false' | 'null' | number)
               <(^(punct | _whitespace))+>

raw_str      = tsq <(^tsq)*> tsq                      -> $2
             | tdq <(^tdq)*> tdq                      -> $2
             | tbq <(^tbq)*> tbq                      -> $2
             | sq <(^sq)*> sq                         -> $2
             | dq <(^dq)*> dq                         -> $2
             | bq <(^bq)*> bq                         -> $2
             | 'L' <sq '='+ sq>:lq
               <(^(={lq}))*> ={lq}                    -> $3

str          = tsq <(~tsq bchar)*> tsq                -> $2
             | tdq <(~tdq bchar)*> tdq                -> $2
             | tbq <(~tbq bchar)*> tbq                -> $2
             | sq <(~sq bchar)*> sq                   -> $2
             | dq <(~dq bchar)*> dq                   -> $2
             | bq <(~bq bchar)*> bq                   -> $2
             | 'L' <sq '='+ sq>:lq
               <(~(={lq}) bchar)*> ={lq}              -> $3

punct        = /(L'=+')|[\/#'"`\[\](){}:=,]/

sq           = "'"

dq           = '"'

bq           = "`"

tsq          = "'''"

tbq          = "```"

tdq          = '"""'

bchar        = bslash escape
             | any

bslash       = '\\'

escape       = bslash
             | [abfnrtv'"`]
             | oct{1,3}
             | 'x' hex{2}
             | 'u' hex{4}
             | 'U' hex{8}
             | 'N{' /[A-Z][A-Z0-9]*(( [A-Z][A-Z0-9]*|(-[A-Z0-9]*)))*/ '}'

nchar        = [0-9A-Z -]

array        = array_tag '[' value? (','? value)* ']' -> ['array', $1,
                                                          concat($3, $4)]

array_tag    = tag ~(_whitespace | _comment)          -> $1

object       = object_tag
               '{' member? (','? member)* '}'         -> ['object', $1,
                                                          concat($3, $4)]

object_tag   = tag ~(_whitespace | _comment)          -> $1

member       = string (':'|'=') value                 -> [$1, $3]

%whitespace  = ws

%comment     = ('#'|'//') ^eol 
             | '/*' ^.'*/'

%tokens      = number | id | string

ws           = [ \n\r\t]*

eol          = '\r\n' | '\r' | '\n'

grammar      = value
             | member+

value        = 'true'                               -> ['true']
             | 'false'                              -> ['false']
             | 'null'                               -> ['null']
             | <number>                             -> ['number', atof($1)]
             | string ('++' string)*                -> ['string', scat($1, $2)]
             | array                                -> ['array', $1]
             | object                               -> ['object', $1]

number       = ('-'|'+')? int frac? exp? 
             | '0b' bin ((bin | '_')* bin)?
             | '0o' oct ((oct | '_')* oct)?
             | '0x' hex ((hex | '_')* hex)?
             | '0X' hex ((hex | '_')* hex)?
             
int          = '0'
             | nonzerodigit digit_sep

digit_sep    = ((digit | '_')* digit)?

digit        = '0' .. '9'

nonzerodiget = '1' .. '9'

frac         = '.' digit_sep 

exp          = ('e'|'E') ('+'|'-')? digit_sep

bin          | '0' | '1'

oct          = '0'..'7'

hex          = '0' .. '9' | 'a' .. 'f' | 'A' .. 'F' 
        
string       = squote sqchar* squote                   -> cat($2)
             | dquote dqchar* dquote                   -> cat($2)
             | bquote bqchar* bquote                   -> cat($2)
             | tsquote tsqchar* tsquote                -> _dedent(cat($2))
             | tdquote tdqchar* tdquote                -> _dedent(cat($2))
             | tbquote tbqchar* tbquote                -> _dedent(cat($2))
             | 'r' squote (~(squote|eol) any)* squote  -> cat($3)
             | 'r' dquote (~(dquote|eol) any)* dquote  -> cat($3)
             | 'r' bquote (~(bquote|eol) any)* bquote  -> cat($3)
             | 'r' tsquote ^tsquote* tsquote           -> _dedent(cat($3))
             | 'r' tdquote ^tdquote* tsquote           -> _dedent(cat($3))
             | 'r' tbquote ^tbquote* tbquote           -> _dedent(cat($3))

squote       = "'"

sqchar       = bslash escape
             | ^(bslash | squote | eol)

dquote       = '"'

dqchar       = bslash escape
             | ^(bslash | dquote | eol)

bquote       = '`'

bqchar       = bslash escape
             | ^(bslash | bquote | eol)

tsquote      = "'''"

tsqchar      = bslash escape
             | ^(bslash tsquote)

tdquote      = '"""'

tdchar       = bslash escape
             | ^(bslash | tdquote)

bslash       = '\\'

escape       = 'b'                                      -> '\b'
             | 'f'                                      -> '\f'
             | 'n'                                      -> '\n'
             | 'r'                                      -> '\r'
             | 't'                                      -> '\t'
             | 'v'                                      -> '\v'
             | '/'                                      -> '/'
             | squote
             | dquote
             | bquote
             | bslash
             | oct_escape
             | hex_escape
             | unicode_escape
             | ~eof any

oct_escape   = ('0'..'7'){1,3}                          -> otoa(cat($1))

hex_escape   = 'x' hex{2}                               -> xtoa(cat($2))
             | 'x' '{' hex{2} '}'                       -> xtoa(cat($3))
uni_escape   = 'u' hex{4}                               -> xtou(cat($2)
             | 'u' '{' hex+ '}'                         -> xtou(cat($3))
             = 'U' hex{8}                               -> xtou(cat($2))

array        = '[' value? (','? value)* ']'             -> acat([$2], $3)
              
object       = '{' member? (','? member)* '}'           -> acat([$2], $3)

member       = key ':' value                            -> [$1, $3]

key          = id
             | string

id           = id_start id_continue*                    -> scat($1, $2)

id_start     = 'a'..'z' 
             | 'A'..'Z'
             | '$'
             | '_'
             | \p{Ll}
             | \p{Lm}
             | \p{Lo}
             | \p{Lt}
             | \p{Lu}
             | \p{Nl}
             | bslash uni_escape

id_continue  = id_start
             | digit
             | \p{Mn}
             | \p{Mc}
             | \p{Nd}
             | \p{Pc}
             | '\u200c'  # zero width non-joiner
             | '\u200d'  # zero width joiner

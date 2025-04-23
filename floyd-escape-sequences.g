escape       = 'a'                                      -> '\a'
             | 'b'                                      -> '\b'
             | 'f'                                      -> '\f'
             | 'n'                                      -> '\n'
             | 'r'                                      -> '\r'
             | 't'                                      -> '\t'
             | 'v'                                      -> '\v'
             | squote
             | dquote
             | bquote
             | bslash
             | oct_esc
             | hex_esc
             | unicode_esc
             | unicode_name

oct_esc      = oct{1,3}                                 -> otou(cat($1))

oct          = '0'..'7'

hex_esc      = 'x' hex{2}                               -> xtou(cat($2))

hex          = '0' .. '9' | 'a' .. 'f' | 'A' .. 'F'

unicode_esc  = 'u' hex{4}                               -> xtou(cat($2))
             | 'U' hex{8}                               -> xtou(cat($2))

unicode_name = 'N{' /[A-Z][A-Z0-9]*(( [A-Z][A-Z0-9]*|(-[A-Z0-9]*)))*/ '}'
                 -> unicode_name($2)

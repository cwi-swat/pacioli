module lang::pacioli::syntax::Lexical

lexical Ident 
	= id: ([A-Za-z_] !<< [a-zA-Z_][a-zA-Z_0-9]* !>> [A-Za-z_0-9]) \ Keywords 
	;

lexical StringConstant = [L]? [\"] StringConstantContent* [\"]
                         ;

lexical StringConstantContent = [\\] ![] |
                                ![\\\"]
                                ;
                                	
lexical Number 
	= [0-9]+"."[0-9]+ !>> [0-9]
	;

lexical Integer 
	= [0-9]+ !>> [0-9.]
	;

lexical Layout 
	= whitespace: [\t-\n\r\ ] 
	| Comment 
	;

layout Layouts = Layout* 
	!>> [\t-\n \r \ ] 
	!>> "(*" 
	;

lexical Comment 
	= @category="Comment"  "(*" CommentChar* "*)" 
	;

lexical CommentChar 
	= ![*] 
	| [*] !>> [)] 
	;

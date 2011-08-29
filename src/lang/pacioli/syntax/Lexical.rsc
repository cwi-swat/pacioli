module lang::pacioli::syntax::Lexical

lexical Ident 
	= id: ([A-Za-z] !<< [a-zA-Z][a-zA-Z0-9]* !>> [A-Za-z0-9]) \ Keywords 
	;
	
lexical Number 
	= [0-9]+"."[0-9]+  !>> [0-9]
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

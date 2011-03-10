module lang::pacioli::syntax::Lexical

syntax LAYOUT = lex whitespace: [\t\n\r\ ] 
              | lex Comment ;

layout LAYOUTLIST = LAYOUT* 
	# [\t\n\r\ ] 
	# "--" ;

syntax Comment = lex "--" ![\n]* [\n] ;

syntax Ident = lex [a-zA-Z][a-zA-Z0-9_]* 
			 - Keyword
       	     # [A-Za-z0-9_]
;

syntax Integer = lex [0-9]+ 
       	       # [0-9];

syntax Number = lex Int:  [0-9]+ 
	      | lex Real: [0-9]+ "." [0-9]+ ;

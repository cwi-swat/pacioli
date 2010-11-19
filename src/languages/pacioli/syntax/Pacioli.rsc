module languages::pacioli::syntax::Pacioli


start syntax Pacioli = Pacioli: Module mod;

syntax LAYOUT = lex whitespace: [\t\n\r\ ] 
              | lex Comment ;

layout LAYOUTLIST = LAYOUT* 
	# [\t\n\r\ ] 
	# "--" ;

syntax Comment = lex "--" ![\n]* [\n] ;

syntax Ident = lex [a-zA-Z][a-zA-Z0-9_]* - "bla"
       	     # [A-Za-z0-9_]
;

syntax Integer = lex [0-9]+ 
       	       # [0-9];

syntax Number = lex Int:  [0-9]+ 
	      | lex Real: [0-9]+ "." [0-9]+ ;

syntax Module = Module: Definition* ;

syntax Definition = Definition: Ident name "=" Expression exp;

syntax Expression = Const: Number
		  | Variable: Ident
		  | TClosure: Expression "+"
		  | TRClosure: Expression "*"
		  >
		  assoc Mul: Expression "*" Expression
		  >
		  assoc InnerMul: Expression "inner" Expression  
		  >  
		  left Div: Expression "/" Expression
		  >  
		  left ( 
		    assoc Add: Expression "+" Expression  
		  | left Sub: Expression "-" Expression
		  ) ; 



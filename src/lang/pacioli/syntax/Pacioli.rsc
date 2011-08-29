module lang::pacioli::syntax::Pacioli

extend lang::pacioli::syntax::Lexical;

start syntax Pacioli = Pacioli: Module mod;

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



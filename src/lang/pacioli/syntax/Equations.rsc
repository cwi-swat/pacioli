module lang::pacioli::syntax::Equations

import lang::pacioli::syntax::Lexical;

/*

something like:

NB: inheritance:
  inherit accounts, transactions, equations
  overriding of equations.
  is multiple inheritance needed? 
  
  
NB: ordering of equations is an operation on this

   
Q: Units are with accounts?
Q: Where are the numbers on the edges in equations?



type WholeSale
	parameters
		vatPercentage: percentage
		salesPrice: currency // cents!
		purPrice: currency
		coll: natural
		pay: natural
	where
		salesPrice > purPrice

	derived
		salesVat = vatPercentage * salesPrice
		purVat = vatPercentage * purPrice
end

NB: # is non-assoc

*/


start syntax Pacioli
	= Equations
	| Type
	;
	
syntax Keyword
	= "type"
	| "buffers"
	| "assets"
	| "liabilities"
	| "equations";
	
syntax Type
	= "type" Ident Section* "end"
	;
	
syntax Section 
	= Buffers
	| Equations
	;
	
syntax Buffers 
	= "buffers" Assets Liabilities
	;

syntax Assets
	= "assets" Decl* 
	;

syntax Liabilities
	= "liabilities" Decl*
	;

syntax Decl
	= Ident ":" Description
	;

syntax Description 
	= lex ![\n]* [\n]
	;
	
syntax Equations 
	= "equations" Equation*
	;

syntax Equation
	= Ident ":" Expression
	;
	
syntax Expression
	= @category="Constant" variable: Ident
	| Ident "[" Ident "]"
	| Ident "@" Ident "[" Ident "]"
	| bracket "(" Expression ")"
	| left mul: Expression "*" Expression
	> left (
		  left add: Expression "+" Expression
		| left sub: Expression "-" Expression
	)
	;

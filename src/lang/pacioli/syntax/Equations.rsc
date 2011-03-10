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
	| Transactions
	| Parameters
	| Deriveds
	| Equations
	;

syntax Transactions
	= @Foldable "transactions" Decl*
	;
	
syntax Parameters
	= @Foldable "parameters" Param* Where?
	;
	
syntax Deriveds
	= "derived" Definition*
	;
	
syntax Definition
	= Ident "=" Expression
	;
	
syntax Param
	= Ident ":" Type
	;
	
syntax Type
	= "natural"
	| "currency"
	| "percentage"
	;
	
syntax Where
	= "where" {Constraint ","}+
	;
	
syntax Constraint 
	= non-assoc (
		Expression "\<" Expression
		| Expression "\<=" Expression
		| Expression "\>" Expression
		| Expression "\>=" Expression
	)
	;
	
	
syntax Buffers 
	= @Foldable "buffers" Assets Liabilities
	;

syntax Assets
	= @Foldable "assets" Decl* 
	;

syntax Liabilities
	= @Foldable "liabilities" Decl*
	;

syntax Decl
	= Ident ":" Description
	;

syntax Description 
	= @category="Comment" lex ![\n]* [\n]
	;
	
syntax Equations 
	= @Foldable "equations" Equation*
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

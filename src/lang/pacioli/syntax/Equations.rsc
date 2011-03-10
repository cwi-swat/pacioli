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

	buffers
	   assets		
		  Deb	: Debtors
		  Art	: Articles
		  Mon	: Money

	   liabilities
		  Cred: Creditors
		  VAT: Value-Added Tax

	transactions
		PayVAT  : Pay VAT
		ColVAT  : Collect VAT
		PayCred	: Pay to Creditors
		ColDeb	: Collect on Debtors
		Sal		: Sales
		Pur		: Purchase 
	

	equations
		Deb	: salesPrice * Sal[Deb] - Col@coll[Deb]
		Art	: Pur[Art] - Sal[Art]
		Cred: purPrice * Pur[Cred] - Pay@pay[Cred]
		Mon	: ColDeb[Mon] + ColVar[Mon] - PayCred[Mon] - PayVAT[Mon]
		VAT	: salesVat * Sal[VAT] - PayVAT@salesVat[VAT] + ColVat@purVat[VAT] - purVat * Pur[VAT] 
end

NB: # is non-assoc

*/


start syntax Pacioli
	= Type
	;
	
syntax Keyword
	= "type"
	| "end"
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
	
syntax Buffers =
	| "buffers" Assets Liabilities "end"
	;

syntax Assets
	= "assets" Decl* "end"
	;

syntax Liabilities
	= "liabilities" Decl* "end"
	;

syntax Decl
	= Ident ":" Description
	;

syntax Description 
	= Ident*
	;
	
syntax Equations 
	= "equations" Equation* "end"
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

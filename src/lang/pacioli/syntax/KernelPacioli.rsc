module lang::pacioli::syntax::KernelPacioli

extend lang::pacioli::syntax::Lexical;


start syntax Expression = variable:Ident name
	| const: Number number
	| bracket "(" Expression nested ")"
	| pair2: "(" Expression first "," Expression second ")"
	| right application: Expression fn Expression arg
	> abstraction: "lambda" Ident var Expression body;

keyword Keywords="lambda";

 
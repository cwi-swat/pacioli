module lang::pacioli::syntax::KernelPacioli

extend lang::pacioli::syntax::Lexical;


start syntax Expression = variable:Ident name
	| const: Number number
	| bracket "(" Expression nested ")"
	| right application: Expression fn Args args
	> abstraction: "lambda" "(" {Ident ","}* vars ")" Expression body;

syntax Args = tup: "(" {Expression ","}* items ")";
 
//keyword Keywords="lambda";

 
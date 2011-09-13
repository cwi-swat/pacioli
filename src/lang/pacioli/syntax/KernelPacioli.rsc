module lang::pacioli::syntax::KernelPacioli

extend lang::pacioli::syntax::Lexical;


start syntax Expression = variable:Ident name
	| const: Number number
	| bracket "(" Expression nested ")"
	| right application: Expression fn Args args
	> neg: "-" Expression
	> trans:  Expression "^T"
	> clos:  Expression "+"
	> assoc joi: Expression "|" Expression
	> left mul: Expression "*" Expression
	> left (
	    assoc sum: Expression "+" Expression
	  | left sub: Expression "-" Expression
	)
	> abstraction: "lambda" "(" {Ident ","}* vars ")" Expression body;

syntax Args = tup: "(" {Expression ","}* items ")";
 
//keyword Keywords="lambda";

 
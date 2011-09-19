module lang::pacioli::syntax::KernelPacioli

extend lang::pacioli::syntax::Lexical;


start syntax Expression = variable:Ident name
	| const: Number number
	| bracket "(" Expression nested ")"
	| comprehension: "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| right application: Expression fn Args args
	> neg: "-" Expression
	> trans:  Expression "^T"
	> clos:  Expression "+"
	> reci: "1/" Expression
	> assoc joi: Expression "." Expression
	> assoc mul: Expression "*" Expression
	> left div: Expression "/" Expression
	> left (
	    assoc sum: Expression "+" Expression
	  | left sub: Expression "-" Expression
	)
	> assoc equal: Expression "=" Expression
	> abstraction: "lambda" "(" {Ident ","}* vars ")" Expression body;

syntax Args = tup: "(" {Expression ","}* items ")";

syntax ComprehensionTerm = generator: Ident name "in" Expression exp;
 
//keyword Keywords="lambda";

 
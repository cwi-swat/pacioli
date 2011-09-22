module lang::pacioli::syntax::KernelPacioli

extend lang::pacioli::syntax::Lexical;


start syntax Expression = variable:Ident name
	| const: Number number
	| constInt: Integer integer
	| bracket "(" Expression nested ")"
	> someComprehension: "some" "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| allComprehension: "all" "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| countComprehension: "count" "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| sumComprehension: "sum" "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| comprehension: "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| right application: Expression fn Args args
	> neg: "-" Expression
	> reci: Expression "^R"
	> trans:  Expression "^T"
	> clos:  Expression "+"
	> kleene:  Expression "*"
	> assoc joi: Expression "." Expression
	> assoc mul: Expression "*" Expression
	> left div: Expression "/" Expression
	> left (
	    assoc sum: Expression "+" Expression
	  | left sub: Expression "-" Expression
	)
	> assoc equal: Expression "=" Expression
	//> not: "!" Expression
	> left (
		assoc and: Expression "&&" Expression
	  | assoc or: Expression "||" Expression
	)
	> abstraction: "lambda" "(" {Ident ","}* vars ")" Expression body;

syntax Args = tup: "(" {Expression ","}* items ")";

syntax ComprehensionTerm = generator: Ident name "in" Expression exp
	| bind: Ident name ":=" Expression exp 
	| filt: Expression exp;
 
//keyword Keywords="lambda";

 
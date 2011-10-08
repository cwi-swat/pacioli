module lang::pacioli::syntax::KernelPacioli

extend lang::pacioli::syntax::Lexical;


start syntax Expression = variable:Ident name
	| const: Number number
	| constInt: Integer integer
	| bracket "(" Expression nested ")"
	| lis: "[" {Expression ","}* items "]"
	| setConstr: "{" {Expression ","}* items "}"
	> someComprehension: "some" "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| allComprehension: "all" "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| countComprehension: "count" "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| sumComprehension: "sum" "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| vecComprehension: "\<" Expression head "|" {ComprehensionTerm ","}* rest "\>"
	| setComprehension: "{" Expression head "|" {ComprehensionTerm ","}* rest "}"
	| gcdComprehension: "gcd" "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
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
	> equal: Expression "=" Expression
	> lesseq: Expression "\<=" Expression
	> less: Expression "\<" Expression
	//> not: "!" Expression
	> left (
		assoc implies: Expression "==\>" Expression
	  | assoc equiv: Expression "\<=\>" Expression
	)
	> left (
		assoc and: Expression "&&" Expression
	  | assoc or: Expression "||" Expression
	)
	> letSuperLuxe: "let" "(" {Ident ","}* vars ")" "=" Expression val "in" Expression body "end"
	> letLuxe: "let" Ident var "(" {Ident ","}* vars ")" "=" Expression val "in" Expression body "end"
	> @Foldable let: "let" Ident var "=" Expression val "in" Expression body "end"
	> branch: "if" Expression cond "then" Expression pos "else" Expression neg "end"
	> abstraction: "lambda" "(" {Ident ","}* vars ")" Expression body;

syntax Args = tup: "(" {Expression ","}* items ")";

syntax ComprehensionTerm 
	= generator: Ident name "in" Expression exp
	//| matrixGenerator: Ident entry "from" Expression exp
	| generatorLuxe: "(" {Ident ","}* vars ")" "in" Expression exp
	| setGenerator: Ident name "elt" Expression exp
	| matrixGenerator: Ident row "," Ident col "from" Expression exp
	| bind: Ident name ":=" Expression exp 
	| bindLuxe: "(" {Ident ","}* vars ")" ":=" Expression exp
	| filt: Expression exp;
 
//keyword Keywords="lambda";

 
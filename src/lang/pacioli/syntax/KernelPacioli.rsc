module lang::pacioli::syntax::KernelPacioli

extend lang::pacioli::syntax::Lexical;


start syntax Expression = variable:Ident name
	| bang: Ident ent "!" Ident unit
	| const: Number number
	| constInt: Integer integer
	| bracket "(" Expression nested ")"
	| lis: "[" {Expression ","}* items "]"
	| setConstr: "{" {Expression ","}* items "}"
	> someComprehension: "some" "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| allComprehension: "all" "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| countComprehension: "count" "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| sumComprehension: "sum" "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| vecComprehension: "\<" Ident row "," Ident column "-\>" Expression head "|" {ComprehensionTerm ","}* rest "\>"
	| setComprehension: "{" Expression head "|" {ComprehensionTerm ","}* rest "}"
	| gcdComprehension: "gcd" "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| comprehension: "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| right application: Expression fn Args args
	> neg: "-" Expression
	> reci: Expression "^R"
	> trans:  Expression "^T"
	> clos:  Expression "+"
	> kleene:  Expression "*"
	> assoc per: Expression "per" Expression
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
	> llet: "let" {LetBinding ","}+ bindings "in" Expression body "end"
	> branch: "if" Expression cond "then" Expression pos "else" Expression neg "end"
	> abstraction: "lambda" "(" {Ident ","}* vars ")" Expression body;

syntax Args = tup: "(" {Expression ","}* items ")";

syntax LetBinding 
	= simpleBinding: Ident var "=" Expression val
	| functionBinding: Ident var "(" {Ident ","}* vars ")" "=" Expression val
	| tupleBinding: "(" {Ident ","}* vars ")" "=" Expression val;

syntax ComprehensionTerm 
	= generator: Ident name "in" "list" Expression exp
	| generatorLuxe: "(" {Ident ","}* vars ")" "in" "list" Expression exp
	| setGenerator: Ident name "in" "set" Expression exp
	| entityGenerator: Ident name "in" "entity" Ident ent
	| matrixGenerator: Ident row "," Ident col "in" "matrix" Expression exp
	| bind: Ident name ":=" Expression exp 
	| bindLuxe: "(" {Ident ","}* vars ")" ":=" Expression exp
	| filt: Expression exp;
 
//keyword Keywords="lambda";

 
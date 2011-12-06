module lang::pacioli::syntax::KernelPacioli

extend lang::pacioli::syntax::Lexical;


start syntax Expression
	= variable:Ident name
	
	| bang: Ident ent "!" Ident unit
	| bangOne: Ident ent "!" "1"
	| scaledUnitConst: Ident prefix ":" Ident unit
	| const: Number number
	| constInt: Integer integer
		
	| litList: "[" {Expression ","}* items "]"
	| litSet: "{" {Expression ","}* items "}"
	
	| bracket "(" Expression nested ")"
	
	> listComprehension: "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| setComprehension: "{" Expression head "|" {ComprehensionTerm ","}* rest "}"
	| vecComprehension: "[" "(" Ident row "," Ident column ")" "-\>" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| opListComprehension: Ident op "[" Expression head "|" {ComprehensionTerm ","}* rest "]"
	| opSetComprehension: Ident op "{" Expression head "|" {ComprehensionTerm ","}* rest "}"
	| opVecComprehension: Ident op "\<" Ident row "," Ident column "-\>" Expression head "|" {ComprehensionTerm ","}* rest "\>"

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
	> notequal: Expression "!=" Expression
	> equal: Expression "=" Expression
	> lesseq: Expression "\<=" Expression
	> less: Expression "\<" !>> "-" Expression
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
	> abstraction: "lambda" "(" {Ident ","}* vars ")" Expression body "end";

syntax Args = tup: "(" {Expression ","}* items ")";

syntax LetBinding 
	= simpleBinding: Ident var "=" Expression val
	| functionBinding: Ident var "(" {Ident ","}* vars ")" "=" Expression val
	| tupleBinding: "(" {Ident ","}* vars ")" "=" Expression val;

syntax ComprehensionTerm 
	= listGenerator: Ident name "\<-" "list" Expression exp
	| listGeneratorLuxe: "(" {Ident ","}* vars ")" "\<-" "list" Expression exp
	| setGenerator: Ident name "\<-" "set" Expression exp
	| setGeneratorLuxe: "(" {Ident ","}* vars ")" "\<-" "set" Expression exp
	| entityGenerator: Ident name "\<-" "entity" Ident ent
	| matrixGenerator: "(" Ident row "," Ident col ")" "\<-" "matrix" Expression exp
	| bind: Ident name ":=" Expression exp 
	| bindLuxe: "(" {Ident ","}* vars ")" ":=" Expression exp
	| filt: Expression exp;
 
//keyword Keywords="zero";

 
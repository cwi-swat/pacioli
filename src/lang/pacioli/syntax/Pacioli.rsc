module lang::pacioli::syntax::Pacioli

extend lang::pacioli::syntax::Lexical;
extend lang::pacioli::syntax::KernelPacioli;

//start syntax Pacioli = Pacioli: Module mod;

start syntax Module = pacioliModule: {ModuleItem ";"}* ;

syntax ModuleItem 
	= schemaImport: "import" StringConstant path
	| fileImport: "include" StringConstant path
	| topLevelExpression: Expression exp
	| valueDefinition: "define" Ident name "=" Expression exp
	| functionDefinition: "define" Ident fn "(" {Ident ","}* args ")" "=" Expression body;


module lang::pacioli::syntax::Pacioli

extend lang::pacioli::syntax::Lexical;
extend lang::pacioli::syntax::KernelPacioli;

//start syntax Pacioli = Pacioli: Module mod;

start syntax Module = pacioliModule: {ModuleItem ";"}* ;

syntax ModuleItem 
	= schemaImport: "Import" StringConstant path
	| fileImport: "Include" StringConstant path
	| topLevelExpression: Expression exp
	| valueDefinition: "Value" Ident name "=" Expression exp
	| functionDefinition: "Function" Ident fn "(" {Ident ","}* args ")" "=" Expression body;


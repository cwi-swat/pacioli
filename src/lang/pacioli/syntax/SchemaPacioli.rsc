module lang::pacioli::syntax::SchemaPacioli

extend lang::pacioli::syntax::Lexical;


start syntax Schema = schema: {SchemaElement ";"}* elements;

syntax SchemaElement = typeDeclaration: Ident name "::" SchemeNode scheme;

syntax SchemeNode
	= schemeNode: "forall" {Ident ","}* vars ":" TypeNode t;
	
syntax TypeNode
	= typeVarNode: Ident name
	| listNode: "List" "(" TypeNode arg ")"
	| setNode: "Set" "(" TypeNode arg ")"
	| tupNode: "Tuple" "(" {TypeNode ","}* items ")"
	| entityNode: "Entity" "(" Ident name ")"
	| functionNode: "(" {TypeNode ","}* args ")" "-\>" TypeNode res
	| functionNodeAlt: TypeNode from "-\>" TypeNode to
	| numNode: "Num" "(" UnitNode singletonUnit ")"
	| matrixNode: "Mat" "(" UnitNode singletonUnit "*" {IndexNode ","}+ rowIndex "per" {IndexNode ","}+ columnIndex ")";
	
syntax IndexNode = halfDuoNode: Ident ent | duoNode: Ident ent "!" UnitNode unit; 

syntax UnitNode
	= unitRef: Ident name
	| unitNum: Number number
	| unitBrack: "(" UnitNode x ")"
	| unitRaiseNode: UnitNode x "^" Integer integer
	| unitNegRaiseNode: UnitNode x "^" "-" Integer integer
	| unitMultNode: UnitNode x "*" UnitNode y;


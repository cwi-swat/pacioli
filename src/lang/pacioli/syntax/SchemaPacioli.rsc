module lang::pacioli::syntax::SchemaPacioli

extend lang::pacioli::syntax::Lexical;


start syntax Schema = schema: {SchemaElement ";"}* elements;

syntax SchemaElement
	= typeDeclaration: Ident name "::" SchemeNode scheme
	| quantityDeclaration: "Quantity" Ident name "\"/" {Ident "/"}+ path "." Ident ext "\""
	| entityDeclaration: "Entity" Ident name "\"/" {Ident "/"}+ path "." Ident ext "\""
	| indexDeclaration: "Index" Ident ent Ident name "\"/" {Ident "/"}+ path "." Ident ext "\""
	| projection: "Projection" Ident name {IndexNode ","}+ rowIndex "per" {IndexNode ","}+ columnIndex
	| conversion: "Conversion" Ident name Ident ent Ident to Ident from
	| baseUnitDeclaration: "Base" "unit" Ident name ":" StringConstant symbol
	| unitDeclaration: "Unit" Ident name ":" StringConstant symbol "=" UnitNode unit;

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
	| unitScaled: Ident prefix UnitNode x
	| unitBrack: "(" UnitNode x ")"
	| unitNegRaiseNode: UnitNode x "^" "-" Integer integer
	> unitRaiseNode: UnitNode x "^" Integer integer
	> unitMultNode: UnitNode x "*" UnitNode y;


module lang::pacioli::syntax::SchemaPacioli

extend lang::pacioli::syntax::Lexical;


start syntax Schema = schema: {SchemaElement ";"}* elements;

syntax SchemaElement
	= typeDeclaration: Ident name "::" SchemeNode scheme
	| quantityDeclaration: "Quantity" Ident name StringConstant path
	| entityDeclaration: "Entity:" Ident name StringConstant path
	| indexDeclaration: "Index" Ident ent "!" Ident name StringConstant path
	| projection: "Projection" Ident name {IndexNode ","}+ rowIndex "per" {IndexNode ","}+ columnIndex
	| conversion: "Conversion" Ident name Ident ent Ident to "per" Ident from
	| baseUnitDeclaration: "Base:" Ident name ":" StringConstant symbol
	| unitDeclaration: "Unit:" Ident name ":" StringConstant symbol "=" UnitNode unit
	| importDeclaration: "Import" StringConstant path;

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
	| matrixNode: "Mat" "(" UnitNode singletonUnit {IndexNode ","}+ rowIndex "per" {IndexNode ","}+ columnIndex ")"
	| simpleMatrixNode: "Mat" "(" {IndexNode ","}+ rowIndex "per" {IndexNode ","}+ columnIndex ")";
	
syntax IndexNode = halfDuoNode: Ident ent | duoNode: Ident ent "!" UnitNode unit; 

syntax UnitNode
	= unitRef: Ident name
	| right unitNegRaiseNode: UnitNode x "^-" Integer integer
	> unitNum: Number number
	| unitScaled: Ident prefix ":" UnitNode x
	> unitBrack: "(" UnitNode x ")"
	> right unitRaiseNode: UnitNode x "^" Integer integer
	> assoc unitMultNode: UnitNode x "*" UnitNode y
	> assoc unitDivNode: UnitNode x "/" UnitNode y;


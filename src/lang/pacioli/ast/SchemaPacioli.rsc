module lang::pacioli::ast::SchemaPacioli

import List;

import units::units;
import lang::pacioli::types::Types;

////////////////////////////////////////////////////////////////////////////////
// Definitions

data Schema = schema(list[SchemaElement] elements);

data SchemaElement = typeDeclaration(str name, SchemeNode scheme);

data SchemeNode = schemeNode(list[str] vars, TypeNode t);

data TypeNode 
	= typeVarNode(str name)
	| listNode(TypeNode arg)
	| setNode(TypeNode arg)
	| tupNode(list[TypeNode] items)
	| entityNode(str name)
	| functionNode(list[TypeNode] args, TypeNode res)
	| functionNodeAlt(TypeNode from, TypeNode to)
	| numNode(UnitNode singletonUnit)
	| matrixNode(UnitNode singletonUnit, list[IndexNode] rowIndex, list[IndexNode] columnIndex);

data IndexNode = halfDuoNode(str ent) | duoNode(str ent, UnitNode unit);

data UnitNode
	= unitRef(str name)
	| unitNum(real number)
	| unitBrack(UnitNode x)
	| unitRaiseNode(UnitNode x, int integer)
	| unitNegRaiseNode(UnitNode x, int integer)
	| unitMultNode(UnitNode x, UnitNode y);

////////////////////////////////////////////////////////////////////////////////
// Normalization

public Schema normalizeSchema(Schema x) = x;

////////////////////////////////////////////////////////////////////////////////
// Translation to Type

public map[str, Scheme] translateSchema(schema(elements)) {
	return (name: scheme | element <- elements, <name,scheme> := translateSchemaElement(element));
}

public tuple[str, Scheme] translateSchemaElement(SchemaElement element) {
	switch (element) {
	case typeDeclaration(name, schemeNode(vars,typ)): {
		translated = translateType(typ, vars);
		tVars = typeVariables(translated);
		eVars = entityVariables(translated);
		uVars = unitVariables(translated);
		return <name, forall(uVars, eVars, tVars, translated)>;
	}
	}
}

public Type translateType(TypeNode typeNode, list[str] vars) {
	switch (typeNode) {
	case typeVarNode(name): return typeVar(name);
	case listNode(arg): return listType(translateType(arg, vars));
	
	case functionNode(args,res): return function(tupType([translateType(arg, vars) | arg <- args]), translateType(res, vars));
	case functionNodeAlt(from,to): return function(translateType(from, vars), translateType(to, vars));
	case setNode(arg): return setType(translateType(arg, vars));
	case entityNode(x): return translateEntity(x, vars);
	case tupNode(items): return tupType([translateType(item, vars) | item <- items]);
	case numNode(x): return translateMatrix(x,[],[], vars);
	case matrixNode(x,y,z): return translateMatrix(x,y,z, vars);
	default: throw "todo: <typeNode>";
	}
}

public Type translateEntity(x, list[str] vars) {
	if (x == "One") {
		return entity(compound([]));
	}
	if (x in vars) {
		return entity(entityVar(x));
	} else {
		return entity(compound([simple(x)]));
	}
}

// todo: units
public Type translateMatrix(x,y,z, list[str] vars) {
	return matrix(translateUnitNode(x, vars), translateIndexNodes(y, vars), translateIndexNodes(z, vars));
}

Unit translateUnitNode(unitNode, list[str] vars) {
	switch (unitNode) {
	case unitRef(x): return (x in vars) ? unitVar(x) : named(x,x,self());
	case unitNum(x): return powerProduct((),x);
	case unitBrack(x): return translateUnitNode(x, vars);
	case unitRaiseNode(x,y): return raise(translateUnitNode(x, vars), y);
	case unitNegRaiseNode(x,y): return raise(translateUnitNode(x, vars), -y);
	case unitMultNode(x,y): return multiply(translateUnitNode(x, vars), translateUnitNode(y, vars));
	default: throw "<unitNode>";
	}
}

// todo: units
Unit indexNodeUnit(IndexNode indexNode, list[str] vars) {
	switch (indexNode) {
	case halfDuoNode(ent): return uno();
	case duoNode(str ent, UnitNode unit): return translateUnitNode(unit, vars);
	}
}

str indexNodeEntity(IndexNode indexNode) {
	switch (indexNode) {
	case halfDuoNode(ent): return ent;
	case duoNode(str ent, UnitNode unit): return ent;
	}
}

public IndexType translateIndexNodes(indexNodes, list[str] vars) {
	if (size(indexNodes) == 0) {
		return duo(compound([]), uno());
	}
	units = [indexNodeUnit(n, vars) | n <- indexNodes];
	unit = (size(units) == 1) ? head(units) : compoundUnit(units);
	entNames = [indexNodeEntity(n) | n <- indexNodes];
	if (size(entNames) == 1 && head(entNames) == "One") {
		return duo(compound([]), uno());
	} else {
		if (size(entNames) == 1 && head(entNames) in vars) {
			return duo(entityVar(head(entNames)), unit);
		} else {
			return duo(compound([simple(n) | n <- entNames]), unit);
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
// Printing

public str pprint(schema(elements)) = intercalate(";\n", [pprint(x) | x <- elements]);

public str pprint(SchemaElement element) {
	switch (element) {
	case typeDeclaration(x,y) : return "<x> :: <pprint(y)>";
	default: return "todo: pprint: <element>";
	}
}

public str pprint(schemeNode(x,y)) = "forall <intercalate(", ", x)>: <pprint(y)>";

public str pprint(SchemeNode schemeNode) {
	switch(schemeNode) {
	case schemeNode(x,y): return "forall <intercalate(", ", x)>: <pprint(y)>";
	default: return "todo pprint: <schemeNode>";
	}
}

public str pprint(TypeNode typeNode) {
	switch (typeNode) {
	case typeVarNode(x): return x;
	case functionNode(args,res): return "(<intercalate(", ", [pprint(x) | x <- args])>) -\> <pprint(res)>";
	case functionNodeAkt(from,to): return "<pprint(from)> -\> <pprint(to)>";
	case listNode(x): return "List(<pprint(x)>)";
	case setNode(x): return "Set(<pprint(x)>)";
	case entityNode(x): return "Entity(<x>)";
	case tupNode(items): return "Tuple(<intercalate(", ", [pprint(x) | x <- items])>)";
	case matrixNode(x,y,z): return "Mat(<x> * <intercalate("*", [pprint(a) | a <- y])> per <intercalate("*", [pprint(a) | a <- z])>)";
	default: return "todo pprint: <typeNode>";
	}
}

public str pprint(IndexNode indexNode) {
	switch(indexNode) {
	case halfDuoNode(x): return x;
	case duoNode(x,y): return "<x>!<y>";
	default: return "todo pprint: <indexNode>";
	}
}

module lang::pacioli::ast::SchemaPacioli

import List;
import String;
import IO;
import units::units;
import lang::pacioli::types::Types;

////////////////////////////////////////////////////////////////////////////////
// Definitions

data Schema = schema(list[SchemaElement] elements);

data SchemaElement
	= typeDeclaration(str name, SchemeNode scheme)
	| quantityDeclaration(str name, str path)
	| entityDeclaration(str name, str path)
	| indexDeclaration(str ent, str name, str path)
	| projection(str name, list[IndexNode] rowIndex, list[IndexNode] columnIndex)
	| conversion(str name, str ent, str to, str from)
	| baseUnitDeclaration(str name, str symbol)
	| unitDeclaration(str name, str symbol, UnitNode unit)
	| importDeclaration(str path);
	
data SchemeNode = schemeNode(list[str] vars, TypeNode t);

data TypeNode 
	= typeVarNode(str name)
	| booleNode() // unused
	| listNode(TypeNode arg)
	| setNode(TypeNode arg)
	| tupNode(list[TypeNode] items)
	| entityNode(str name)
	| functionNode(list[TypeNode] args, TypeNode res)
	| functionNodeAlt(TypeNode from, TypeNode to)
	| numNode(UnitNode singletonUnit)
	| simpleMatrixNode(list[IndexNode] rowIndex, list[IndexNode] columnIndex)
	| matrixNode(UnitNode singletonUnit, list[IndexNode] rowIndex, list[IndexNode] columnIndex);

data IndexNode = halfDuoNode(str ent) | duoNode(str ent, UnitNode unit);

data UnitNode
	= unitRef(str name)
	| unitNum(real number)
	//| unitInt(int integer)
	//| unitNeg(UnitNode x)
	| unitBrack(UnitNode x)
	| unitScaled(str prefix, UnitNode x)
	| unitRaiseNode(UnitNode x, int integer)
	| unitNegRaiseNode(UnitNode x, int integer)
	| unitMultNode(UnitNode x, UnitNode y);

////////////////////////////////////////////////////////////////////////////////
// Normalization

public Schema normalizeSchema(Schema x) {
	//return x;
	return innermost visit(x) {
		case simpleMatrixNode(x,y) => matrixNode(1,x,y)
	}
}

////////////////////////////////////////////////////////////////////////////////
// Fetch entities and indices

public list[str] fetchImports(schema(list[SchemaElement] elements)) {
	return [substring(path,1,size(path)-1) | importDeclaration(str path) <- elements];
}

public map[str, str] fetchBaseUnits(schema(list[SchemaElement] elements)) {
	return (name: symbol | baseUnitDeclaration(str name, str symbol) <- elements);
}

public map[str, tuple[str, Unit]] fetchUnits(schema(list[SchemaElement] elements)) {
	return (name: <symbol, translateUnitNode(unit, [])> | unitDeclaration(str name, str symbol, UnitNode unit) <- elements);
}

public map[str, str] fetchFileLocations(schema(list[SchemaElement] elements)) {
	return (name: path | quantityDeclaration(str name, str path) <- elements);
}

public map[str, str] fetchEntities(schema(list[SchemaElement] elements)) {
	return (name: path | entityDeclaration(str name, str path) <- elements);
}

public map[str, tuple[IndexType,IndexType]] fetchProjections(schema(list[SchemaElement] elements)) {
	return (name: <translateIndexNodes(rowIndex, []), translateIndexNodes(columnIndex, [])> | projection(str name, list[IndexNode] rowIndex, list[IndexNode] columnIndex) <- elements);
}

public map[str, tuple[str,str,str]] fetchConversions(schema(list[SchemaElement] elements)) {
	return (name: <ent, to, from> | conversion(str name, str ent, str to, str from) <- elements);
}

public map[str, tuple[str,str,str]] fetchIndices(schema(list[SchemaElement] elements)) {
	return (full: <ent, name, path> | 
					indexDeclaration(str ent, str name, str path) <- elements, 
					full := ent + "!" + name);
}

////////////////////////////////////////////////////////////////////////////////
// Translation to Type

public map[str, Scheme] translateSchema(schema(elements)) {
	return (name: scheme | SchemaElement element <- elements, typeDeclaration(_,_) := element, <str name,Scheme scheme> := translateSchemaElement(element));
}

public tuple[str, Scheme] translateSchemaElement(SchemaElement element) {
	switch (element) {
	case typeDeclaration(str name, schemeNode(list[str] vars, TypeNode typ)): {
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
	case typeVarNode("Boole"): return boolean();
	case typeVarNode(str name): return typeVar(name);
	case booleNode(): return boolean(); // unused
	case listNode(TypeNode arg): return listType(translateType(arg, vars));
	case functionNode(list[TypeNode] args, TypeNode res): return function(tupType([translateType(arg, vars) | arg <- args]), translateType(res, vars));
	case functionNodeAlt(TypeNode from, TypeNode to): return function(translateType(from, vars), translateType(to, vars));
	case setNode(TypeNode arg): return setType(translateType(arg, vars));
	case entityNode(str x): return translateEntity(x, vars);
	case tupNode(list[TypeNode] items): return tupType([translateType(item, vars) | item <- items]);
	case numNode(UnitNode x): return translateMatrix(x,[],[], vars);
	case matrixNode(UnitNode x,list[IndexNode] y,list[IndexNode] z): return translateMatrix(x,y,z, vars);
	// Waarom werkt schemaNormalize niet ?
	case simpleMatrixNode(list[IndexNode]  y, list[IndexNode] z): return translateMatrix(unitNum(1.0),y,z, vars);
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

public Type translateMatrix(x,y,z, list[str] vars) {
	return matrix(translateUnitNode(x, vars), translateIndexNodes(y, vars), translateIndexNodes(z, vars));
}

Unit translateUnitNode(UnitNode unitNode, list[str] vars) {
	switch (unitNode) {
	case unitRef(str x): return (x in vars) ? unitVar(x) : named(x,x,self());
	case unitNum(real x): return powerProduct((),x);
	case unitInt(int i): return powerProduct((),i*1.0);
	case unitBrack(UnitNode x): return translateUnitNode(x, vars);
	//case unitNeg(x): return multiply(translateUnitNode(x, vars), powerProduct((),-1.0));
	// todo: factor wegwerken uit prefix()
	case unitScaled(str p, UnitNode x): return scaled(translateUnitNode(x, vars), prefix(p, 123.0));
	case unitRaiseNode(UnitNode x, int y): return raise(translateUnitNode(x, vars), y);
	case unitNegRaiseNode(UnitNode x, int i): return raise(translateUnitNode(x, vars), -i);
	case unitMultNode(UnitNode x, UnitNode y): return multiply(translateUnitNode(x, vars), translateUnitNode(y, vars));
	default: throw "Cannot translate unitNode <unitNode>";
	}
}

//Unit translateUnitNode(unitNode, list[str] vars) {
//	switch (unitNode) {
//	case unitRef(x): return (x in vars) ? unitVar(x) : named(x,x,self());
//	case unitNum(x): return powerProduct((),x);
//	case unitInt(i): return powerProduct((),i*1.0);
//	case unitBrack(x): return translateUnitNode(x, vars);
//	//case unitNeg(x): return multiply(translateUnitNode(x, vars), powerProduct((),-1.0));
//	// todo: factor wegwerken uit prefix()
//	case unitScaled(p, x): return scaled(translateUnitNode(x, vars), prefix(p, 123.0));
//	case unitRaiseNode(x,y): return raise(translateUnitNode(x, vars), y);
//	case unitNegRaiseNode(x,i): return raise(translateUnitNode(x, vars), -i);
//	case unitMultNode(x,y): return multiply(translateUnitNode(x, vars), translateUnitNode(y, vars));
//	default: throw "Cannot translate unitNode <unitNode>";
//	}
//}

Unit indexNodeUnit(IndexNode indexNode, list[str] vars) {
	switch (indexNode) {
	case halfDuoNode(str ent): return uno();
	case duoNode(str ent, UnitNode unit): return translateUnitNode(unit, vars);
	}
}

str indexNodeEntity(IndexNode indexNode) {
	switch (indexNode) {
	case halfDuoNode(str ent): return ent;
	case duoNode(str ent, UnitNode unit): return ent;
	}
}

public IndexType translateIndexNodes(indexNodes, list[str] vars) {
	if (size(indexNodes) == 0) {
		return duo(compound([]), uno());
	}
	units = [indexNodeUnit(n, vars) | IndexNode n <- indexNodes];
	unit = (size(units) == 1) ? head(units) : compoundUnit(units);
	entNames = [indexNodeEntity(n) | IndexNode n <- indexNodes];
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
	case functionNodeAlt(from,to): return "<pprint(from)> -\> <pprint(to)>";
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

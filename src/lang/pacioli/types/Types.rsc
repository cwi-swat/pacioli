module lang::pacioli::types::Types

import Map;
import Set;
import List;

import units::units;

import lang::pacioli::ast::KernelPacioli;


data Scheme = forall(set[str] unitVars,
					 set[str] entityVars,
					 set[str] typeVars,
					 Type t);

public str pprint(forall(unitVars, entityVars, typeVars, typ)) {
	vars = [x | x <- typeVars + entityVars + unitVars];
	if (vars == []) {
		return pprint(typ);
	} else {
		return "forall <commaSeparated(vars)>: <pprint(typ)>";
	}
}

str commaSeparated(list[str] xs) {
	if (xs == []) {
		return "";
	} else {
		return (head(xs) | it + ", " + x | x <- tail(xs));
	}
}

data Type = typeVar(str name)
          | function(Type from, Type to)
          | tupType(list[Type] items)
          | listType(Type arg)
          | setType(Type arg)
          | boolean()
          | entity(EntityType entity)
          | matrix(Unit factor, IndexType rowType, IndexType columnType);

data IndexType 
  = duo(EntityType entity, Unit unit)
  ;

data EntityType
  = entityVar(str name)
  | compound(list[SimpleEntity] types)
  ;

data SimpleEntity = simple(str name);

public int order(compound(x)) = size(x);
public int order(duo(x,_)) = oder(x);

public set[str] entityVariables(x) = {name | /entityVar(name) <- x};
 
public set[str] typeVariables(x) = {name | /typeVar(name) <- x};

public str pprint(Type t) {
	switch (t) {
		case typeVar(x): return "\'<x>";
		case matrix(a,pu0,qv0): {
			fact = pprint(a);
			row = pprint(pu0);
			col = pprint(qv0);
			rows = (row == "(empty).(1)") ? "" : "<row>";
			cols = (col == "(empty).(1)") ? "" : " per <col>";
			front = (fact == "1" && (rows != "" || cols != "")) ? "" : "<fact>";
			sep = (front != "" && rows != "") ? " * " : "";
			constr = "Mat";
			if (rows == "") {constr = "Vec";}
			if (cols == "") {constr = "Vec";}
			if (rows == "" && cols == "") {constr = "Num";} 	
			return "<constr>\<<front><sep><rows><cols>\>";
		}
		case function(x,y): return "<pprint(x)> -\> <pprint(y)>";
		case tupType([]): return "()";
		case tupType(x): return "(<(pprint(head(x)) | it + ", " + pprint(y) | y <- tail(x))>)";
		case listType(x): return "List\<<pprint(x)>\>";
		case setType(x): return "Set\<<pprint(x)>\>";
		case boolean(): return "Boole";
		case entity(x): return "<pprint(x)>";
	}
} 

	
private str pprintSimpleIndex(simple(name), Unit unit) {
	return "<name><(unit == uno()) ? "" : ".<pprint(unit)>">";
}

private list[tuple[SimpleEntity,Unit]] indexList(list[SimpleEntity] entities, Unit unit) {
	return [ <entities[i],nthUnit(unit,i)> | i <- [0..size(entities)-1]];
}

public str serial (duo(EntityType entity, Unit unit)){
	compound(x) = entity;
	if (x == []) {
		return "Empty";
	} else {
		front = ("<pprint(head(x))>" | "<it>,<pprint(y)>" | y <- tail(x));
		return front + "." + serial(unit);
	}
}

public str pprint(duo(EntityType entity, Unit unit)) {

	switch (entity) {
		case entityVar(x): return "\'<x>.<pprint(unit)>";
		case compound([]): return "(empty).(1)";
		default: {
			if (entityVariables(entity) == {} && unitVariables(unit) == {} && compound(x) := entity) {
				if (x == []) {
					return "(empty).(1)";
				} else {
					simpleIndices = [pprintSimpleIndex(ent,un) | <ent,un> <- indexList(x,unit)];
					return ("<head(simpleIndices)>" | "<it>*<y>" | y <- tail(simpleIndices));
				} 
			} else {
				return "(<pprint(entity)>).(<pprint(unit)>)";
			}
		}
	}
} 

public str pprint(EntityType t) {
	switch (t) {
		case entityVar(x): return "\'<x>";
		case compound([]): return "Empty";
		case compound(x): return ("<pprint(head(x))>" | "<it>*<pprint(y)>" | y <- tail(x)); 
	}
}

public str pprint(simple(x)) = x;


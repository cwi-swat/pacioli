module lang::pacioli::types::Types

import Map;
import Set;
import List;

import units::units;
import lang::pacioli::ast::KernelPacioli;

////////////////////////////////////////////////////////////////////////////////
// Definitions 

data Scheme = forall(set[str] unitVars, set[str] entityVars, set[str] typeVars, 
                     Type t);

data Type = typeVar(str name)
          | function(Type from, Type to)
          | tupType(list[Type] items)
          | listType(Type arg)
          | setType(Type arg)
          | boolean()
          | entity(EntityType entity)
          | matrix(Unit factor, IndexType rowType, IndexType columnType);

data IndexType = duo(EntityType entity, Unit unit);

data EntityType = entityVar(str name) | compound(list[SimpleEntity] types);

data SimpleEntity = simple(str name);

////////////////////////////////////////////////////////////////////////////////
// Logic 

public int order(compound(x)) = size(x);

public int order(duo(x,_)) = oder(x);

public set[str] entityVariables(x) = {name | /entityVar(name) <- x};
 
public set[str] typeVariables(x) = {name | /typeVar(name) <- x};


private list[tuple[SimpleEntity,Unit]] indexList(list[SimpleEntity] entities, Unit unit) {
	return [ <entities[i],nthUnit(unit,i)> | i <- [0..size(entities)-1]];
}

////////////////////////////////////////////////////////////////////////////////
// Printing 

public str pprint(forall(unitVars, entityVars, typeVars, typ)) {
	vars = [x | x <- typeVars + entityVars + unitVars];
	if (vars == []) {
		return pprint(typ);
	} else {
		return "forall <intercalate(", ", vars)>: <pprint(typ)>";
	}
}

public str pprint(Type t) {
	switch (t) {
		case typeVar(x): return x;
		case matrix(a,pu0,qv0): {
			fact = pprint(a);
			row = pprint(pu0);
			col = pprint(qv0);
			rows = (row == "One") ? "" : "<row>";
			cols = (col == "One") ? "" : " per <col>";
			front = (fact == "1" && (rows != "" || cols != "")) ? "" : "<fact>";
			sep = (front != "" && rows != "") ? " * " : "";
			constr = "Mat";
			if (rows == "") {constr = "Vec";}
			if (cols == "") {constr = "Vec";}
			if (rows == "" && cols == "") {constr = "Num";} 	
			return "<constr>(<front><sep><rows><cols>)";
		}
		case function(tupType(x),y): return "(<intercalate(", ", [pprint(a) | a <- x])>) -\> <pprint(y)>";
		case function(x,y): return "<pprint(x)> -\> <pprint(y)>";
		case tupType(x): return "Tuple(<intercalate(", ", [pprint(a) | a <- x])>)";
		case listType(x): return "List(<pprint(x)>)";
		case setType(x): return "Set(<pprint(x)>)";
		case boolean(): return "Boole";
		case entity(x): return "<pprint(x)>";
		default: throw "huh <t>";
	}
} 

private str pprintSimpleIndex(simple(name), Unit unit) {
	return "<name><(unit == uno()) ? "" : "!<pprint(unit)>">";
}

public str pprint(duo(EntityType entity, Unit unit)) {
	switch (entity) {
		case entityVar(x): return pprintSimpleIndex(simple(x),unit);
		case compound([]): return "One";
		case compound(x): return intercalate("*", [pprintSimpleIndex(ent,un) | <ent,un> <- indexList(x,unit)]);
	}
} 

public str pprint(EntityType t) {
	switch (t) {
		case entityVar(x): return x;
		case compound([]): return "One";
		case compound(x): return intercalate("*", [pprint(e) | e <- x]);
	}
}

public str pprint(simple(x)) = x;

////////////////////////////////////////////////////////////////////////////////
// Serializing (format understood by the MVM) 

public str serial (duo(EntityType entity, Unit unit)){
	switch (entity) {
		case entityVar(x): {
			throw "Cannot serialize open type expression <pprint(duo(entity, unit))>";
		}
		case compound([]): return "One";
		case compound(x): return intercalate(",", [pprint(d) | d <- x]) + "!" + serial(unit);
	}
}

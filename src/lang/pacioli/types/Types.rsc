module lang::pacioli::types::Types

import Map;
import Set;
import List;
//import IO;

import units::units;
import lang::pacioli::ast::KernelPacioli;
//import lang::pacioli::utils::Implode;

////////////////////////////////////////////////////////////////////////////////
// General Utilities

public int glbcounter = 0;

public str fresh(str x) {glbcounter += 1; return "<x><glbcounter>";}



data Scheme = forall(set[str] unitVars,
					 set[str] entityVars,
					 set[str] typeVars,
					 Type t);

data Type = typeVar(str name)
          | function(Type from, Type to)
          | pair(Type first, Type second)
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
			return "<front><sep><rows><cols>";
		}
		case function(x,y): return "(<pprint(x)> -\> <pprint(y)>)";
		case pair(x,y): return "(<pprint(x)>,<pprint(y)>)";
		default: return "<t>";
	}
} 
public str pprint(duo(EntityType entity, Unit unit)) {

	private list[tuple[SimpleEntity,Unit]] indexList(list[SimpleEntity] entities, Unit unit) {
		return [ <entities[i],nthUnit(unit,i)> | i <- [0..size(entities)-1]];
	}
	
	private str pprintSimpleIndex(simple(name), Unit unit) {
		return "<name><(unit == uno()) ? "" : ".<pprint(unit)>">";
	}

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
		case compound([]): return "empty";
		case compound(x): return ("<pprint(head(x))>" | "<it>*<pprint(y)>" | y <- tail(x)); 
	}
}

public str pprint(simple(x)) = x;

module lang::pacioli::types::Types

import Map;
import Set;
import List;
import IO;

import units::units;
import units::unification;
import lang::pacioli::ast::KernelPacioli;
import lang::pacioli::utils::Implode;

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

public Scheme schemeSubs(substitution(ub, eb, tb),
						 forall(unitVars, entityVars, typeVars, typ)) {
	return forall(unitVars, entityVars, typeVars,
				  typeSubs(substitution(
				  			(key: ub[key] | key <- ub, !(key in unitVars)),
					        (key: eb[key] | key <- eb, !(key in entityVars)),
					        (key: tb[key] | key <- tb, !(key in typeVars))),
					       typ)); 
}

public Type instScheme(forall(unitVars, entityVars, typeVars, typ)) {
	EntityBinding eb = (x: entityVar(fresh("E")) | x <- entityVars);
	UnitBinding ub = (x: unitVar(fresh("u")) | x <- unitVars);
	TypeBinding tb = (x: typeVar(fresh("t")) | x <- typeVars);
	return typeSubs(substitution(ub,eb,tb), typ);
}

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

////////////////////////////////////////////////////////////////////////////////
// Tests

public Environment env() {

	Unit gram = named("g", self());
	Unit metre = named("m", self());
	Unit second = named("s", self());
	Unit dollar = named("$", self());

	IndexType empty = duo(compound([]), uno());
	
	EntityType Product = compound([simple("Product")]);
	Unit tradeUnit = named("trade_unit", self());
	Unit bomUnit = named("bom_unit", self());
	
	IndexType tradeIndex = duo(Product, tradeUnit);
	IndexType bomIndex = duo(Product, bomUnit);
	
	SimpleEntity Commodity = simple("Commodity");
	SimpleEntity Year = simple("Year");
	SimpleEntity Region = simple("Region");
	Unit commodityUnit = named("unit", self());


  return (
   "gram": forall({},{},{}, matrix(gram, empty, empty)),
   "metre": forall({},{},{}, matrix(metre, empty, empty)),
   "second": forall({},{},{}, matrix(second, empty, empty)),
   "dollar": forall({},{},{}, matrix(dollar, empty, empty)),
   "bom": forall({},{},{}, matrix(uno(), bomIndex, bomIndex)),
   "conv": forall({},{},{}, matrix(uno(), tradeIndex, bomIndex)),
   "output": forall({},{},{}, matrix(uno(), tradeIndex, empty)),
   "purchase_price": forall({},{},{}, matrix(uno(), tradeIndex, empty)),
   "sales_price": forall({},{},{}, matrix(dollar, empty, tradeIndex)),
   "sales": forall({},{},{}, matrix(dollar, empty, duo(compound([Commodity, Year, Region]), uno()))),
   "amount": forall({},{},{}, matrix(uno(), duo(compound([Commodity, Year, Region]), compoundUnit([commodityUnit, uno(), uno()])), empty)),
   "P0": forall({},{},{}, matrix(uno(), duo(compound([Commodity, Year, Region]), uno()), duo(compound([Commodity]), uno()))),
   "P1": forall({},{},{}, matrix(uno(), duo(compound([Commodity, Year, Region]), uno()), duo(compound([Commodity, Year]), uno()))),   
   "P2": forall({},{},{}, matrix(uno(), duo(compound([Year, Commodity]), compoundUnit([uno(), commodityUnit])),
                                        duo(compound([Commodity, Year, Region]), compoundUnit([commodityUnit, uno(), uno()])))),
   "P3": forall({},{},{}, matrix(uno(), duo(compound([Year]), uno()),
                                        duo(compound([Commodity, Year, Region]), compoundUnit([commodityUnit, uno(), uno()])))),
   "join": forall({"a", "b", "u", "v", "w"},{"P", "Q", "R"},{},
  				  function(pair(matrix(unitVar("a"), 
  				  					   duo(entityVar("P"), unitVar("u")),
  				  					   duo(entityVar("Q"), unitVar("v"))),
  				  				matrix(unitVar("b"), 
  				  					   duo(entityVar("Q"), unitVar("v")),
  				  					   duo(entityVar("R"), unitVar("w")))),
				           matrix(multiply(unitVar("a"), unitVar("b")), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("R"), unitVar("w"))))),
	"transpose": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("Q"), reciprocal(unitVar("v"))),
  				  				  duo(entityVar("P"), reciprocal(unitVar("u")))))),
	"total": forall({"a"},{"P", "Q"},{},
  				  function(matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), uno()),
  				  				  duo(entityVar("Q"), uno())),
				           matrix(unitVar("a"), 
  				  				  empty,
  				  				  empty))),
	"sqrt": forall({"a"},{},{},
  				  function(matrix(multiply(unitVar("a"),unitVar("a")), 
  				  				  duo(compound([]), uno()),
  				  				  duo(compound([]), uno())),
				           matrix(unitVar("a"), 
  				  				  duo(compound([]), uno()),
  				  				  duo(compound([]), uno())))),
   "sum": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(pair(matrix(unitVar("a"), 
  				  					   duo(entityVar("P"), unitVar("u")),
  				  					   duo(entityVar("Q"), unitVar("v"))),
  				  				matrix(unitVar("a"), 
  				  					   duo(entityVar("P"), unitVar("u")),
  				  					   duo(entityVar("Q"), unitVar("v")))),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))))),
   "multiply": forall({"a", "b", "u", "v", "w", "z"},{"P", "Q"},{},
				function(pair(matrix(unitVar("a"), 
  				  					 duo(entityVar("P"), unitVar("u")),
  				  					 duo(entityVar("Q"), unitVar("v"))),
  				  			  matrix(unitVar("b"), 
  				  					 duo(entityVar("P"), unitVar("w")),
  				  					 duo(entityVar("Q"), unitVar("z")))),
				         matrix(multiply(unitVar("a"), unitVar("b")), 
  				  				duo(entityVar("P"), multiply(unitVar("u"), unitVar("w"))),
  				  				duo(entityVar("Q"), multiply(unitVar("v"), unitVar("z")))))),
   "negative": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))))),
   "closure": forall({"u"},{"P"},{},
  				  function(matrix(uno(), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("P"), unitVar("u"))),
				           matrix(uno(), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("P"), unitVar("u"))))),
   "reciprocal": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))),
				           matrix(reciprocal(unitVar("a")), 
  				  				  duo(entityVar("P"), reciprocal(unitVar("u"))),
  				  				  duo(entityVar("Q"), reciprocal(unitVar("v")))))));
}

public void show (str exp) {
	try {
		glbcounter = 0;
		glbstack = [];
		parsed = parseImplodePacioli(exp);
		<typ, _> = inferType(parsed, env());
		println("<pprint(parsed)> :: <pprint(unfresh(typ))>");
	} catch err: {
		println(err);
	}

	
}
	
public void showAll() {
	show("lambda x join(x,x)");
	show("lambda x join(bom,x)");
	show("lambda x sum(sum(x,x),sum(x,x))");
	show("lambda x multiply(sum(x,x),sum(x,x))");
	show("lambda x total multiply (x,x)");
	show("lambda x sqrt total multiply (x,x)");
	show("lambda x lambda y join (sum(x,negative(y)),sum(y,negative(x)))");
	show("lambda x lambda y sum(join(x,y),negative(join(y,x)))");
	show("(lambda bom2 join(bom2,output)) join(conv,join(bom,reciprocal transpose conv))");
	show("(lambda bom2 closure bom2) join(conv,join(bom,reciprocal transpose conv))");
	show("multiply(sales,reciprocal transpose amount)");
	show("(lambda price multiply(join(price, reciprocal transpose P2),join(price, reciprocal transpose P2))) multiply(sales,reciprocal transpose amount)");
	show("(lambda price join(price, reciprocal transpose P2)) multiply(sales,reciprocal transpose amount)");
}


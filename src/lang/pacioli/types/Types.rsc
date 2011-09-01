module lang::pacioli::types::Types

import Map;
import Set;
import List;
import IO;

import lang::pacioli::ast::KernelPacioli;
import lang::pacioli::utils::Implode;

////////////////////////////////////////////////////////////////////////////////
// Required mathematical functions

public real abs(real x) = (x < 0.0) ? -x : x;
public int abs(int x) = (x < 0) ? -x : x;  

private real expt(real x, int e) {
	if (e == 0) {
		return 1.0;
	}
	if (e < 0) {
		return 1 / expt(x, -e);
	}
	return x * expt(x, e  - 1);
}

public int floor(int x, int div) {
	if (x % div == 0 || x*div > 0) {
		return x/div;
	} else  {
		(x-div)/div;
	}
}

////////////////////////////////////////////////////////////////////////////////
// General Utilities

public int glbcounter = 0;

public str fresh(str x) {glbcounter += 1; return "<x><glbcounter>";}

////////////////////////////////////////////////////////////////////////////////
// Units

alias Powers = map[Unit units, int powers];

data Unit
  = unitVar(str name)
  | self()
  | named(str symbolic, Unit definition)
  | scaled(Unit unit, Prefix prefix)
  | powerProduct(Powers powers, real factor)
  | compoundUnit(list[Unit])
  ;
  
data Prefix
  = prefix(str symbolic, real factor)
  ; 
  
public set[Unit] bases(powerProduct(Powers ps, real _)) = ps.units;
  
public int power(powerProduct(powers, _), Unit base) = powers[base] ? 0;
public int power(Unit u, u) = 1;

public real factor(powerProduct(_, x), Unit base) = x;
  
public default set[Unit] bases(Unit u) = {u};

public default int power(Unit _, Unit _) = 0;

public default real factor(Unit _) = 1.0;

public Unit powerProduct(powers, 1.0) {
  if (size(powers) == 1, u <- powers, powers[u] == 1) {
    return u;
  }
  fail;
}
    
public Unit multiply(Unit u1, Unit u2) =  
  powerProduct((base: p | base <- bases(u1) + bases(u2), 
                          p := power(u1, base) + power(u2, base), 
                          p != 0), 
               factor(u1) * factor(u2));

public Unit raise(Unit u, int pwr) = 
  powerProduct((b: p | b <- bases(u),
                       p := pwr * power(u, b),
                       p != 0),
               expt(factor(u), pwr));

public Unit divide(Unit u1, Unit u2) = multiply(u1, reciprocal(u2));

public Unit reciprocal(Unit u) = raise(u,-1);

public Unit uno() = powerProduct((), 1.0);

public Unit nthUnit(Unit unit, int n) {
	return mapUnit(Unit(Unit u) {
	 	switch(u) {
	 		case compoundUnit(x): return x[n];
	 		default: return u;
		}
	}, unit); 
}

public &T foldUnit(&T(Unit) baseFun, &T(&T, &T) productFun, &T(&T) inverse, Unit unit, &T init) {
  // Is een call van baseFun op uno() ipv init argument ook een optie? of op nul args? Meen me te 
  // herinneren dat het een slecht idee is. Waarom heeft de Lisp fold geen init?
	lst = [];
	for (x <- bases(unit)) {
		base = baseFun(x);
		pwr = power(unit, x);
		elt = (pwr < 0) ? inverse(base) : base;
		lst += [elt | _ <- [1..abs(pwr)]];
	}
	return ( init | productFun(it, x) | x <- lst );
}

public Unit mapUnit(Unit(Unit) fn, Unit unit) = 
  foldUnit(fn, multiply, reciprocal, unit, uno());

public Unit filterUnit(bool(Unit) fn, Unit unit) = 
  mapUnit(Unit(Unit u) { return (fn(u)) ? u : uno(); }, unit);

public str pprint(Unit u) {
	switch (u) {
		case named(x,_): return x;
		case unitVar(x): return "\'<x>";
		case powerProduct(p, f): {
			text = (f == 1.0) ? "" : "<f>*";
			for (x <- p,p[x]>0) {
				//text = text + "·<pprint(x)><(p[x] == 1) ? "" : "^<p[x]>">";
				text = text + "<pprint(x)><(p[x] == 1) ? "" : "^<p[x]>">";
			}
			if ({x | x <- p, p[x]<0} != {}) {
				text = text + "/";
			}
			for (x <- p, p[x]<0) {
				//text = text + "·<pprint(x)><(p[x] == 1) ? "" : "^<p[x]>">";
				po = -p[x];
				text = text + "<pprint(x)><(po == 1) ? "" : "^<po>">";
			}
			if (text == "") {
				text = "1";
			}
			return text;
		}
		case compoundUnit([]): {
			return "1";
		}
		case compoundUnit(units): {
			return (pprint(head(units)) | "<it>*<pprint(x)>" | x <- tail(units));
		}
		default: return "<u>";
	}
} 

////////////////////////////////////////////////////////////////////////////////
// Unit unification

alias UnitBinding = map[str, Unit];
  
public Unit unitSubs(UnitBinding b, Unit un) {
	return mapUnit(Unit(Unit u) {
		switch (u) {
			case unitVar(x): return (x in b ? unitSubs(b, b[x]): u);
			default: return u;
		}		  
	}, un);
} 

public set[str] unitVariables(Unit u) = {b | unitVar(b) <- bases(u)};

public tuple[bool, UnitBinding] unifyUnits(Unit u1, Unit u2, UnitBinding binding) {
 
	tuple[bool, UnitBinding] unify(Unit uni, UnitBinding b) {
		unit = unitSubs(b, uni);
		vars = filterUnit(bool (Unit u) {return u is unitVar;}, unit);
    	nonVars = filterUnit(bool (Unit u) {return !(u is unitVar);}, unit);
     	nrVars = size(bases(vars));
    	if (nrVars == 0) {
    		if (size(bases(nonVars)) == 0) {
      			return <true, b>;
      		} else {
      			glberror = "unit failure: <pprint(unitSubs(b,u1))> vs <pprint(unitSubs(b,u2))>";
      			return <false, b>;
      		}
    	} else {
      		Unit minBase = minBase(vars);
      		unitVar(name) = minBase;
			minp = power(unit, minBase);      		
	      	if (nrVars == 1) {
	       		if (bases(nonVars) == {} || 
	       			all(Unit x <- bases(nonVars),
	       		    	power(unit, x) % minp == 0)) {
	           		return <true, mergeUnits(b, (name: raise(nonVars, -1 / minp)))>;
	       		} else {
	       			glberror = "unit failure: <pprint(unitSubs(b,u1))> vs <pprint(unitSubs(b,u2))>";
	         		return <false, b>;
	       		}
	      	} else {
	      		Unit subst = uno();
	      		for (base <- bases(unit)) {
	      			if (base != minBase) {
	      				p = floor(power(unit, base), power(unit, minBase));
	      				subst = multiply(subst, raise(base, -p));
	      			}
	      		}
	      		return unify(unit, mergeUnits(b, (name: subst)));
	      	}
    	}
	}
	return unify(multiply(u1, reciprocal(u2)), binding);
}

private Unit minBase(Unit metas) {
	private int f(base) = abs(power(metas, base));
	baseList = [b | b <- bases(metas)];
	return (head(baseList) | (f(it) > f(x)) ? x : it | x <- baseList);
}

////////////////////////////////////////////////////////////////////////////////
// Types

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
 
public set[str] unitVariables(matrix(a,b,c)) = unitVariables(a)+unitVariables(b)+unitVariables(c);
public set[str] unitVariables(duo(a,b)) = unitVariables(b);
public set[str] unitVariables(function(x,y)) = unitVariables(x)+unitVariables(y);
public set[str] unitVariables(pair(x,y)) = unitVariables(x)+unitVariables(y);
public set[str] unitVariables(_) = {};

public set[str] entityVariables(entityVar(x)) = {x};
public set[str] entityVariables(compound(x)) = ({} | it + entityVariables(s) | s <- x);
public set[str] entityVariables(matrix(a,b,c)) = entityVariables(b)+entityVariables(c);
public set[str] entityVariables(duo(a,b)) = entityVariables(a);
public set[str] entityVariables(function(x,y)) = entityVariables(x)+entityVariables(y);
public set[str] entityVariables(pair(x,y)) = entityVariables(x)+entityVariables(y);
public set[str] entityVariables(_) = {};
 
public set[str] typeVariables(typeVar(x)) = {x};
public set[str] typeVariables(function(x,y)) = typeVariables(x)+typeVariables(y);
public set[str] typeVariables(pair(x,y)) = typeVariables(x)+typeVariables(y);
public set[str] typeVariables(_) = {};

public str pprint(Type t) {
	switch (t) {
		case typeVar(x): return "\'<x>";
		case matrix(a,pu0,qv0): {
			fact = pprint(a);
			row = pprint(pu0);
			col = pprint(qv0);
			front = (fact == "1") ? "" : "<fact>";	
			rows = (row == "(empty).(1)") ? "" : "<row>";
			cols = (col == "(empty).(1)") ? "" : " per <col>";
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
// EntityType unification

alias EntityBinding = map[str, EntityType];

public EntityType entitySubs(EntityBinding b, EntityType typ) {
	switch (typ) {
		case entityVar(x): return (x in b) ? entitySubs(b, b[x]) : typ;
		default: return typ;
	}
}

public tuple[bool, EntityBinding] unifyEntities(EntityType x, EntityType y, EntityBinding binding) {

	private tuple[bool, EntityBinding] unifyVar(str var, EntityType b) {
		if (var in binding) {
			return unifyEntities(binding[var], b, binding);
		} else {
			return <true, mergeEntities(binding, (var: b))>;
		}	
	}
	
	switch (<x,y>) {
		case <compound(a), compound(a)>: return <true, binding>;
		case <entityVar(a), entityVar(a)>: return <true, binding>; 
		case <EntityType a, entityVar(b)>: return unifyVar(b,a); 
		case <entityVar(a), EntityType b>: return unifyVar(a,b); 
		default: {
			glberror = "entity failure: <pprint(x)> and <pprint(y)>";
			return <false, ()>;
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
// Type unification

alias TypeBinding = map[str, Type];

data Substitution = substitution(UnitBinding units, 
								 EntityBinding entities, 
								 TypeBinding types);

public Substitution ident = substitution((),(),());

public bool containsType (substitution(ub,eb,tb), str name) = name in tb;

public Substitution bindUnitVar(str key, Type typ) = substitution((key: typ),(),()); 
public Substitution bindEntityVar(str key, Type typ) = substitution((),(key: typ),());
public Substitution bindTypeVar(str key, Type typ) = substitution((),(),(key: typ));

public Type unfresh(Type t) {
	s = substitution(unitUnfresh(unitVariables(t)),entityUnfresh(entityVariables(t)),());
	return typeSubs(s,t);
}

public UnitBinding unitUnfresh(set[str] variables) {
	int counter = 0;
	private int f() {counter = counter + 1; return counter-1;};
	return (name: unitVar("u<f()>") | name <- variables);
}

public EntityBinding entityUnfresh(set[str] variables) {
	int counter = 0;
	private int f() {counter = counter + 1; return counter-1;};
	return (name: entityVar("E<f()>") | name <- variables);
}

public Substitution merge(substitution(ub0,eb0,tb0), substitution(ub1,eb1,tb1)) {
	return substitution(mergeUnits(ub0,ub1),
						mergeEntities(eb0,eb1),
				 		(x: typeSubs(substitution((),(),tb1), tb0[x]) | x <- tb0) + tb1);
}

public UnitBinding mergeUnits(UnitBinding bindingX, UnitBinding bindingY) {
	return (x: unitSubs(bindingY, bindingX[x]) | x <- bindingX) + bindingY;
}

public EntityBinding mergeEntities(EntityBinding bindingX, EntityBinding bindingY) {
	return (x: entitySubs(bindingY, bindingX[x]) | x <- bindingX) + bindingY;
}

public Type typeSubs(Substitution s, Type typ) {
	substitution(bu,be,bt) = s;
	switch (typ) {
		case typeVar(x): return (x in bt) ? typeSubs(s, bt[x]) : typ;
		case matrix(a,duo(p,u),duo(q,v)): 
			return matrix(unitSubs(bu,a),
						  duo(entitySubs(be,p), unitSubs(bu,u)),
						  duo(entitySubs(be,q), unitSubs(bu,v)));
		case function(x,y): return function(typeSubs(s, x), typeSubs(s, y));
		case pair(x,y): return pair(typeSubs(s, x), typeSubs(s, y));
		default: return typ;
	}
}

public tuple[bool, Substitution] unifyTypes(Type x, Type y, Substitution binding) {

	private tuple[bool, Substitution] unifyVar(str var, Type b) {
		if (containsType(binding, var)) {
			return unifyTypes(typeSubs(binding, typeVar(var)), b, binding);
			
		} else {
			if (var in typeVariables(b)) {
				glberror = "cycle";
				return <false, ident>;
			}
			return <true, merge(binding, bindTypeVar(var,b))>;
		}	
	}
	
	public tuple[bool, Substitution] unifyMatrices(a,duo(p0,u0),duo(q0,v0),
												   b,duo(p1,u1),duo(q1,v1),
	                                       		   substitution(bu,be,bt)) { 
	    
		<success0, S0> = unifyUnits(a,b, bu);
		if (!success0) return <false, ident>;
		<success1, S1> = unifyEntities(p0, p1, be);
		if (!success1) return <false, ident>;
		<success2, S2> = unifyEntities(q0, q1, S1);
		if (!success2) return <false, ident>;
		<success3, S3> = unifyUnits(u0, u1, bu);
		if (!success3) return <false, ident>;
		<success4, S4> = unifyUnits(v0, v1, S3);
		if (!success4) return <false, ident>;
		return <true, substitution(mergeUnits(S0,S4),S2,bt)>;
	}

	switch (<x,y>) {
		case <matrix(a,pu0,qv0), matrix(b,pu1,qv1)>:
			return unifyMatrices(a,pu0,qv0, b,pu1,qv1, binding);
		case <function(a,b), function(c,d)>: {
			<success, s1> = unifyTypes(a,c, binding);
			if (!success) return <false, ident>;
			<success, s2> = unifyTypes(b,d, s1);
			if (!success) return <false, ident>;
			return <true, s2>;
		}
		case <pair(a,b), pair(c,d)>: {
			<success, s1> = unifyTypes(a,c, binding);
			if (!success) return <false, ident>;
			<success, s2> = unifyTypes(b,d, s1);
			if (!success) return <false, ident>;
			return <true, s2>;
		}
		case <typeVar(a), typeVar(a)>: {
			return <true, binding>;
		}
		case <typeVar(a), Type b>: {
			return unifyVar(a,b);
		}
		case <Type a, typeVar(b)>: {
			return unifyVar(b,a);
		}
		default: {
			println("Unify fallthrough!!!!!\n <x>\n <y>");
			return <false,ident>;
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
// Type Inference

alias Environment = map[str, Scheme];

public Environment envSubs(Substitution s, Environment e) {
	return (key: schemeSubs(s, e[key]) | key <- e);
}

public list[str] glbstack = [];
public str glberror = "so far, so good";

public tuple[Type, Substitution] inferType(Expression exp, Environment assumptions) {
	push("<pprint(exp)>");
	switch (exp) {
		case variable(x): {
			typ = instScheme(assumptions[x]);
			pop("<pprint(typ)>");
			return <typ, ident>;
		}
		case pair2(x,y): {
			<t1, s1> = inferType(x, assumptions);
			<t2, s2> = inferType(y, envSubs(s1, assumptions));
			typ = typeSubs(s2, pair(t1, t2));
			pop("<pprint(typ)>");
			return <typ, merge(s1,s2)>;
		}
		case application(x,y): {
			<funType, s1> = inferType(x, assumptions);
			<argType, s2> = inferType(y, envSubs(s1, assumptions));
			s12 = merge(s1,s2);
			beta = fresh("identifier");
			template = function(argType, typeVar(beta));
			<succ, s3> = unifyTypes(typeSubs(s2, funType), template, s12);
			if (succ) {
				s123 = merge(s12,s3);
				typ = typeSubs(s123, typeVar(beta));
				pop("<pprint(typ)>");
				return <typ, s123>;
			} else {
				throw("\nType error: <glberror>\n\nStack:<("" | "<it>\n<frame>" | frame <- glbstack)>");
			}
		}
		case abstraction(x,b): {
			beta = fresh(x);
			<t1, s1> = inferType(b, assumptions+(x: forall({},{},{},typeVar(beta))));
			typ = typeSubs(s1,function(typeVar(beta), t1));
			pop("<pprint(typ)>");
			return <typ, s1>;
		}
	}
}

public void push(str log) {
	glbstack = [log] + glbstack;
	n = size(glbstack)-1; 
	//println("<filler(n)><n>\> <head(glbstack)>");
}

public void pop(str log) {
	n = size(glbstack)-1;
	//println("<filler(n)><n>\< <log>");
	glbstack = tail(glbstack); 
}

public str filler(int n) = (n==0) ? "" : ("" | it + " " | _ <- [1..n]); 

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
	glbstack = [];
	parsed = parseImplodePacioli(exp);
	<typ, _> = inferType(parsed, env());
	println("<pprint(parsed)> :: <pprint(unfresh(typ))>");
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

////////////////////////////////////////////////////////////////////////////////
// Compilation

alias Register = map[str var, str register];

public str compilePacioli(Expression exp) {
	prelude = "baseunit dollar \"$\";
			  'baseunit euro \"€\";
			  'unit litre \"l\" (deci metre)^3;
			  'unit pound \"lb\" 0.45359237*kilo gram;
			  'unit ounce \"oz\" pound/16;
			  'unit barrel \"bbl\" 117.347765*litre;
	          'entity Product \"/home/paul/data/code/mvm/case1/product.txt\";
			  'index Product bom_unit \"/home/paul/data/code/mvm/case1/product.bom_unit\";
			  'index Product trade_unit \"/home/paul/data/code/mvm/case1/product.trade_unit\";
			  'conversion conv \"Product\" \"bom_unit\" \"trade_unit\";
			  'load output \"/home/paul/data/code/mvm/case1/output.csv\" \"1\" \"Product.trade_unit\" \"empty\";
			  'load purchase_price \"/home/paul/data/code/mvm/case1/purchase_price.csv\" \"euro\" \"empty\" \"Product.trade_unit\";
			  'load sales_price \"/home/paul/data/code/mvm/case1/sales_price.csv\" \"euro\" \"empty\" \"Product.trade_unit\";
			  'load bom \"/home/paul/data/code/mvm/case1/bom.csv\" \"1\" \"Product.bom_unit\" \"Product.bom_unit\";
			  'entity Commodity \"case2/commodity.txt\";
			  'entity Year \"case2/year.txt\";
			  'entity Region \"case2/region.txt\";
			  'index Commodity unit \"case2/commodity.unit\";
			  'load sales \"case2/sales.csv\" \"dollar\" \"empty\" \"Commodity,Year,Region.1\";
			  'load amount \"case2/amount.csv\" \"1\" \"Commodity,Year,Region.unit,1,1\" \"empty\";
			  'projection P0 \"Commodity,Year,Region.1\" \"Commodity.1\";
			  'projection P1 \"Commodity,Year,Region.1\" \"Commodity,Year.1\";
			  'projection P2 \"Year,Commodity.1,unit\" \"Commodity,Year,Region.unit,1,1\"";
	<code,reg> = compileExpression(exp,());
	prog = "<prelude>;
		   '<code>; 
	       'print <reg>";
	return prog;
}

public tuple[str,str] compileExpression(Expression exp, Register reg) {
	switch (exp) {
		case variable(x): {
			return <"skip", (x in reg) ? reg[x] : x>; 
		}
		case application(abstraction(var,body),arg): {
			<c1,r1> = compileExpression(arg,reg);
			<c2,r2> = compileExpression(body,reg+(var:r1));
			return <"<c1>;\n<c2>", r2>;
		}
		case application(variable(fn),pair2(a,b)): {
			<c1,r1> = compileExpression(a,reg);
			<c2,r2> = compileExpression(b,reg);
			r = fresh("r");
			return <"<c1>;\n<c2>;\n<fn> <r> <r1> <r2>", r>;
		}
		case application(variable(fn),arg): {
			<c1,r1> = compileExpression(arg,reg);
			r = fresh("r");
			return <"<c1>;\n<fn> <r> <r1>", r>;
		}
		default: throw("Functions and pairs as values not (yet) supported");
	}
}

public void showGen (str exp) {
	parsed = parseImplodePacioli(exp);
	code = compilePacioli(parsed);
	println(code);
}

// 1) huidige 1e. Moet unit als type noemen+Kennedy?.
// 2)
// BoM in tweede paragraph. Shows
// (i) It needs units: obvious
// (ii) It is a matrix: linear algebra  
// (iii) Units are heterogeneous: no parametric polymorphism
// (iv) Products are not known at compile time: no exhaustive record type
// 3) matrix type
// 4) contributions: 1) units in vectors spaces 2) type 3) prototype 


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

public int counter = 0;

public str fresh(str x) {counter += 1; return "<x><counter>";}

////////////////////////////////////////////////////////////////////////////////
// Units

alias Powers = map[Unit units, int powers];

data Unit
  = unitVar(str name)
  | self()
  | named(str symbolic, Unit definition)
  | scaled(Unit namedUnit, Prefix prefix)
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
    
public bool unitLess (Unit u) = bases(u) == {};

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

public Unit divide(Unit u1, Unit u2) = multiply(u1, raise(u2,-1));

public Unit reciprocal(Unit u) = raise(u,-1);

public Unit uno() = powerProduct((), 1.0);

public &T foldUnit(&T(Unit) baseFun, &T(&T, &T) productFun, &T(&T) inverse, Unit unit, &T init) {
  // Is een call van baseFun op uno() ipv init argument ook een optie? Meen me te 
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
			for (x <- p) {
				//text = text + "·<pprint(x)>^<p[x]>";
				text = text + "<pprint(x)>^<p[x]>";
			}
			if (text == "") {
				text = "1";
			}
			return text;
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
      			error = "unit failure: <pprint(unitSubs(b,u1))> vs <pprint(unitSubs(b,u2))>";
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
	       			error = "unit failure: <pprint(unitSubs(b,u1))> vs <pprint(unitSubs(b,u2))>";
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
	return unify(multiply(u1, raise(u2, -1)), binding);
}

// Hoe te folden zonder initial value?
private Unit minBase(Unit metas) {
	m = abs(power(metas, maxBase(metas)));
	Unit base;
    for (x <- bases(metas)) {
    	p = abs(power(metas, x));
    	if (p <= m) {
    		m = p;
    		base = x; 
    	}
    }
    return base;
}

public Unit maxBase(Unit metas) {
	m = 0;
	Unit base;
    for (x <- bases(metas)) {
    	p = abs(power(metas, x));
    	if (p >= m) {
    		m = p;
    		base = x;
    	}
    }
    return base;
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

public str pprint(duo(EntityType entity, Unit unit)) {
	unitText = (unit == uno()) ? "" : ".<pprint(unit)>";
	switch (entity) {
		case entityVar(x): return "\'<x><unitText>";
		case compound([]): return "empty";
		case compound(x): {
			simpleIndices = [pprintSimpleIndex(ent,un) | <ent,un> <- indexList(x,unit)];
			return ("<head(simpleIndices)>" | "<it> * <y>" | y <- tail(simpleIndices));
		}
	}
} 


private list[tuple[SimpleEntity,Unit]] indexList(list[SimpleEntity] entities, Unit unit) {
	switch (<entities,unit>) {
		case <[],_>: return [];
		case <x, compoundUnit(y)>: {
			return [<head(x),head(y)>] + indexList(tail(x), compoundUnit(tail(y)));
		}
		case <x, y>: {
			return [<head(x),y>] + indexList(tail(x), y);
		}
		default: println(<entities,unit>);
	}
}

private str pprintSimpleIndex(simple(name), Unit unit) {
	return "<name><(unit == uno()) ? "" : ".<pprint(unit)>">";
}

public str pprint(Type t) {
	switch (t) {
		case typeVar(x): return "\'<x>";
		case matrix(a,pu0,qv0): {
			fact = pprint(a);
			row = pprint(pu0);
			col = pprint(qv0);
			front = (fact == "1") ? "" : "<fact>";	
			rows = (row == "empty") ? "" : "<row>";
			cols = (col == "empty") ? "" : " per <col>";
			sep = (front != "" && rows != "") ? " * " : "";
			return "<front><sep><rows><cols>";
		}
		case function(x,y): return "(<pprint(x)> -\> <pprint(y)>)";
		case pair(x,y): return "(<pprint(x)>,<pprint(y)>)";
		default: return "<t>";
	}
} 

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
			error = "entity failure: <x> and <y>";
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
			// todo: decide on unification strategy
			//if (var in typeVariables(typeSubs(binding,b))) {
			if (var in typeVariables(b)) {
				error = "cycle";
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

public list[str] stack = [];
public str error = "so far, so good";

public str filler(int n) = (n==0) ? "" : ("" | it + " " | _ <- [1..n]); 

public void push(str log) {
	stack = [log] + stack;
	n = size(stack); 
	println("<filler(n)><n>\> <head(stack)>");
}

public void pop(str log) {
	n = size(stack);
	println("<filler(n)>\<<n> <log>");
	stack = tail(stack); 
}

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
			fn = typeSubs(s2, funType);
			template = function(argType, typeVar(beta));
			<succ, s3> = unifyTypes(fn, template, s12);
			if (succ) {
				s123 = merge(s12,s3);
				typ = typeSubs(s123, typeVar(beta));
				pop("<pprint(typ)>");
				return <typ, s123>;
			} else {
				println("app FAILURE!!!!!!!!! <error> \n <exp>\n <fn>\n <template>\n\n<stack>");
			}
		}
		case abstraction(x,b): {
			beta = fresh(x);
			<t1, s1> = inferType(b, assumptions+(x: forall({},{},{},typeVar(beta))));
			typ = typeSubs(s1,function(typeVar(beta), t1));
			pop("<pprint(typ)>");
			return <typ, s1>;
		}
		default: println("<exp>  FAILURE!!!!!!!!! <error> \n\n<stack>");
	}
}

////////////////////////////////////////////////////////////////////////////////
// Tests

public Unit gram = named("g", self());
public Unit metre = named("m", self());
public Unit dollar = named("$", self());

//public Type vt0 = typeVar("t0");
//public Type vt1 = typeVar("t1");
//public Type vt2 = typeVar("t2");
//public Unit va0 = unitVar("a0");  // scalar by convention
//public Unit va1 = unitVar("a1");
//public Unit vu0 = unitVar("u0");  // vector by convention
//public Unit vu1 = unitVar("u1");
//public Unit vu2 = unitVar("u2");
//public EntityType vP = entityVar("P");
//public EntityType vQ = entityVar("Q");
//public EntityType vR = entityVar("R");

// unifyUnits(gram, gram, ());
// unifyUnits(gram, metre, ());
// unifyUnits(vu0, metre, ());
// unifyUnits(vu0, multiply(metre, gram), ());
// unifyUnits(vu0, multiply(metre, vu1), ());
// unifyUnits(gram, multiply(metre, vu1), ());
// unifyUnits(gram, multiply(vu0, vu1), ());
// unifyUnits(gram, multiply(vu1, vu1), ());
// unifyUnits(gram, multiply(raise(vu0,2), vu1), ());

public IndexType empty = duo(compound([]), uno());

public EntityType Product = compound([simple("Product")]);
public Unit tradeUnit = named("trade_unit", self());
public Unit bomUnit = named("bom_unit", self());

public IndexType tradeIndex = duo(Product, tradeUnit);
public IndexType bomIndex = duo(Product, bomUnit);


public SimpleEntity Commodity = simple("Commodity");
public SimpleEntity Year = simple("Year");
public SimpleEntity Region = simple("Region");
public Unit commodityUnit = named("unit", self());

//public IndexType commodityUnitIndex = duo(Commodity, commodityUnit);
//public IndexType commodityIndex = duo(Commodity, uno());
//public IndexType yearIndex = duo(Year, uno());
//public IndexType regionIndex = duo(Region, uno());


//public Type mt1 = matrix(uno(), bomIndex, bomIndex);
//public Type mt2 = matrix(va0, duo(vP, vu0), duo(vQ, vu1));
//
//public Type mt3 = matrix(va0, duo(vP, vu0), bomIndex);
//public Type mt4 = matrix(va1, duo(vQ, vu1), duo(vQ, vu1));


// unifyTypes(mt1, mt1, ident);
// unifyTypes(mt1, mt2, ident);
// typeSubs(substitution(("u0": gram, "u1": metre),(),()), mt2);
  
public Environment env =
  ("bom": forall({},{},{}, matrix(uno(), bomIndex, bomIndex)),
   "conv": forall({},{},{}, matrix(uno(), tradeIndex, bomIndex)),
   "output": forall({},{},{}, matrix(uno(), tradeIndex, empty)),
   "purchase_price": forall({},{},{}, matrix(uno(), tradeIndex, empty)),
   "sales_price": forall({},{},{}, matrix(dollar, empty, tradeIndex)),
   "sales": forall({},{},{}, matrix(dollar, empty, duo(compound([Commodity, Year, Region]), compoundUnit([commodityUnit, uno(), uno()])))),
   "amount": forall({},{},{}, matrix(uno(), duo(compound([Commodity, Year, Region]), uno()), empty)),   
   "P0": forall({},{},{}, matrix(uno(), duo(compound([Commodity, Year, Region]), uno()), duo(compound([Commodity]), uno()))),
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
	"trans": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("Q"), raise(unitVar("v"),-1)),
  				  				  duo(entityVar("P"), raise(unitVar("u"),-1))))),
	"sum": forall({"a"},{"P", "Q"},{},
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
   "plus": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(pair(matrix(unitVar("a"), 
  				  					   duo(entityVar("P"), unitVar("u")),
  				  					   duo(entityVar("Q"), unitVar("v"))),
  				  				matrix(unitVar("a"), 
  				  					   duo(entityVar("P"), unitVar("u")),
  				  					   duo(entityVar("Q"), unitVar("v")))),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))))),
   "mult": forall({"a", "b", "u", "v", "w", "z"},{"P", "Q"},{},
				function(pair(matrix(unitVar("a"), 
  				  					 duo(entityVar("P"), unitVar("u")),
  				  					 duo(entityVar("Q"), unitVar("v"))),
  				  			  matrix(unitVar("b"), 
  				  					 duo(entityVar("P"), unitVar("w")),
  				  					 duo(entityVar("Q"), unitVar("z")))),
				         matrix(multiply(unitVar("a"), unitVar("b")), 
  				  				duo(entityVar("P"), multiply(unitVar("u"), unitVar("w"))),
  				  				duo(entityVar("Q"), multiply(unitVar("v"), unitVar("z")))))),
   "minus": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))))),
   "reci": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))),
				           matrix(raise(unitVar("a"),-1), 
  				  				  duo(entityVar("P"), raise(unitVar("u"), -1)),
  				  				  duo(entityVar("Q"), raise(unitVar("v"), -1))))));


public void show (str exp) {
	<t, s> = inferType(parseImplodePacioli(exp), env); 
	println(pprint(t));
}
	
public void showAll() {
	stack = [];
	show("lambda x join(x,x)");
	show("lambda x join(bom,x)");
	show("lambda x plus(plus(x,x),plus(x,x))");
	show("lambda x mult(plus(x,x),plus(x,x))");
	show("lambda x sum mult (x,x)");
	show("lambda x sqrt sum mult (x,x)");
	show("lambda x lambda y join (plus(x,minus(y)),plus(y,minus(x)))");
	show("lambda x lambda y plus(join(x,y),minus(join(y,x)))");
	show("(lambda bom2 join(bom2,output)) join(conv,join(bom,reci trans conv))");
	show("mult(sales,reci trans amount)");
}

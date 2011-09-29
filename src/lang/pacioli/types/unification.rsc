module lang::pacioli::types::unification

import Map;
import Set;
import List;
import IO;

import units::units;
import units::unification;

import lang::pacioli::ast::KernelPacioli;
import lang::pacioli::utils::Implode;
import lang::pacioli::types::Types;


////////////////////////////////////////////////////////////////////////////////
// EntityType unification

alias EntityBinding = map[str, EntityType];


public EntityType entitySubs(EntityBinding b, EntityType typ) {
	switch (typ) {
		case entityVar(x): return (x in b) ? entitySubs(b, b[x]) : typ;
		default: return typ;
	}
}

public EntityBinding unifyEntities(EntityType x, EntityType y) {
	private EntityBinding unifyVar(str var, EntityType b) {
		if (var in entityVariables(b)) {
			throw "Conflict: <pprint(x)> = <pprint(y)>";
		}	
		return (var: b);
	}
	
	switch (<x,y>) {
		case <compound(a), compound(a)>: return ();
		case <entityVar(a), entityVar(a)>: return (); 
		case <EntityType a, entityVar(b)>: return unifyVar(b,a); 
		case <entityVar(a), EntityType b>: return unifyVar(a,b); 
		default: {
			error = "entity failure: <pprint(x)> and <pprint(y)>";
			throw error;
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
	s = substitution(unitUnfresh(unitVariables(t)),entityUnfresh(entityVariables(t)),typeUnfresh(typeVariables(t)));
	return typeSubs(s,t);
}

public TypeBinding typeUnfresh(set[str] variables) {
	int counter = 0;
	private int f() {counter = counter + 1; return counter-1;};
	return (name: typeVar("t<f()>") | name <- variables);
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
				 		(x: t | x <- tb0, t := typeSubs(substitution((),(),tb1), tb0[x]), notIsVar(t,x)) + tb1);
}

public bool notIsVar(t,v) {
	switch (t) {
	case typeVar(x): return x != v;
	default: return true; 
	}
}

public bool notIsEntityVar(t,v) {
	switch (t) {
		case entityVar(x): return x != v;
		default: return true; 
	}
}

public EntityBinding mergeEntities(EntityBinding bindingX, EntityBinding bindingY) {
	return (x: t | x <- bindingX, t := entitySubs(bindingY, bindingX[x]), notIsEntityVar(t,x)) + bindingY;
}

public Type typeSubs(Substitution s, Type typ) {
	//println("typeSubs  <pprint(typ)>  <s>");
	substitution(bu,be,bt) = s;
	switch (typ) {
		case typeVar(x): {
			return (x in bt) ? typeSubs(s, bt[x]) : typ;
		}
		case matrix(a,duo(p,u),duo(q,v)): 
			return matrix(unitSubs(bu,a),
						  duo(entitySubs(be,p), unitSubs(bu,u)),
						  duo(entitySubs(be,q), unitSubs(bu,v)));
		case function(x,y): return function(typeSubs(s, x), typeSubs(s, y));
		case tupType(x): return tupType([typeSubs(s,y) | y <- x]);
		case listType(x): return listType(typeSubs(s,x));
		case setType(x): return setType(typeSubs(s,x));
		case entity(x): return entity(entitySubs(be,x));
		case boolean(): return typ;
		default: throw "In typeSubs: <pprint(typ)> unknown";
	}
}

public Substitution unifyTypes(Type x, Type y) {

	private Substitution unifyVar(str var, Type b) {
		if (var in typeVariables(b)) {
			throw "Conflict: <pprint(x)> = <pprint(y)>";
		}	
		return bindTypeVar(var,b);
	}

	public Substitution unifyMatrices(a,duo(p0,u0),duo(q0,v0),
												   b,duo(p1,u1),duo(q1,v1)) { 
	    
		A0 = unifyUnits(a,b);
		E1 = unifyEntities(p0, p1);
		E2 = mergeEntities(E1, unifyEntities(entitySubs(E1,q0), entitySubs(E1,q1)));
		U1 = unifyUnits(u0, u1);
		U2 = mergeUnits(U1, unifyUnits(unitSubs(U1,v0), unitSubs(U1,v1)));
		return substitution(A0+U2,E2,());
	}

	switch (<x,y>) {
		case <typeVar(a), typeVar(a)>: {
			return ident;
		}
		case <typeVar(a), Type b>: {
			return unifyVar(a,b);
		}
		case <Type a, typeVar(b)>: {
			return unifyVar(b,a);
		}
		case <matrix(a,pu0,qv0), matrix(b,pu1,qv1)>:
			return unifyMatrices(a,pu0,qv0, b,pu1,qv1);
		case <function(a,b), function(c,d)>: {
			S1 = unifyTypes(a,c);
			S2 = merge(S1, unifyTypes(typeSubs(S1,b),typeSubs(S1,d)));
			return S2;
		}
		case <entity(a), entity(b)>: {
			return substitution((),unifyEntities(a, b),());
		}
		case <tupType([]), tupType([])>: {
			return ident;
		}
		case <a,tupType([])>: {
			throw "Incorrect number of arguments";
		}
		case <tupType([]), a>: {
			throw "Incorrect number of arguments";
		}
		case <tupType(a), tupType(b)>: {
			S1 = unifyTypes(head(a),head(b));
			S2 = merge(S1,unifyTypes(typeSubs(S1,tupType(tail(a))),typeSubs(S1,tupType(tail(b)))));
			return S2;
		}
		case <listType(a), listType(b)>: {
			return unifyTypes(a,b);
		}
		case <setType(a), setType(b)>: {
			return unifyTypes(a,b);
		}
		case <boolean(), boolean()>: {
			return ident;
		}
		default: {
			throw "Cannot unify types <pprint(x)> and <pprint(y)> <x> <y>";
		}
	}
}


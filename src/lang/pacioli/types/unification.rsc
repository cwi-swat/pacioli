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
		//case entityVar(x): return (x in b) ? entitySubs(b, b[x]) : typ;
		case entityVar(x): return (x in b) ? b[x] : typ;
		default: return typ;
	}
}

//public tuple[bool, Substitution] unifyEntitiesLuxe(EntityType x, EntityType y, substitution(ub,eb,tb)) {
//	//<succes,binding> = unifyEntities(x,y,eb);
//	binding = unifyEntities(x,y);
//	// is dit goed?
//	return substitution(ub,mergeEntities(eb,binding),tb);
//	//return <succes,substitution(ub,binding,tb)>;
//}

//public tuple[bool, EntityBinding] unifyEntities(EntityType x, EntityType y, EntityBinding binding) {
public EntityBinding unifyEntities(EntityType x, EntityType y) {

	private EntityBinding unifyVar(str var, EntityType b) {
		//if (var in binding) {
		//	return unifyEntities(binding[var], b, binding);
		//} else {
		//	return <true, mergeEntities(binding, (var: b))>;
		//}	
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
				 		(x: typeSubs(substitution((),(),tb1), tb0[x]) | x <- tb0) + tb1);
}


public EntityBinding mergeEntities(EntityBinding bindingX, EntityBinding bindingY) {
	return (x: entitySubs(bindingY, bindingX[x]) | x <- bindingX) + bindingY;
}

public Type typeSubs(Substitution s, Type typ) {
	//println("typeSubs <s> <typ>");
	substitution(bu,be,bt) = s;
	switch (typ) {
		case typeVar(x): return (x in bt) ? typeSubs(s, bt[x]) : typ;
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

//public tuple[bool, Substitution] unifyTypes(Type x, Type y, Substitution binding) {
public Substitution unifyTypes(Type x, Type y) {

	//private tuple[bool, Substitution] unifyVar(str var, Type b) {
	private Substitution unifyVar(str var, Type b) {
		//if (containsType(binding, var)) {
		//	return unifyTypes(typeSubs(binding, typeVar(var)), b, binding);
		//	
		//} else {
		//	if (var in typeVariables(b)) {
		//		error = "cycle";
		//		throw error;
		//		//return <false, ident>;
		//	}
		//	return <true, merge(binding, bindTypeVar(var,b))>;
		//}
		
		if (var in typeVariables(b)) {
			throw "Conflict: <pprint(x)> = <pprint(y)>";
		}	
		return bindTypeVar(var,b);
	}
	
	//public tuple[bool, Substitution] unifyMatrices(a,duo(p0,u0),duo(q0,v0),
	//											   b,duo(p1,u1),duo(q1,v1),
	//                                       		   substitution(bu,be,bt)) { 
	//    
	//	<success0, S0> = unifyUnits(a,b, bu);
	//	if (!success0) return <false, ident>;
	//	<success1, S1> = unifyEntities(p0, p1, be);
	//	if (!success1) return <false, ident>;
	//	<success2, S2> = unifyEntities(q0, q1, S1);
	//	if (!success2) return <false, ident>;
	//	<success3, S3> = unifyUnits(u0, u1, bu);
	//	if (!success3) return <false, ident>;
	//	<success4, S4> = unifyUnits(v0, v1, S3);
	//	if (!success4) return <false, ident>;
	//	return <true, substitution(mergeUnits(S0,S4),S2,bt)>;
	//}

	public Substitution unifyMatrices(a,duo(p0,u0),duo(q0,v0),
												   b,duo(p1,u1),duo(q1,v1)) { 
	    
		A0 = unifyUnits(a,b);
		E1 = unifyEntities(p0, p1);
		E2 = mergeEntities(E1, unifyEntities(entitySubs(E1,q0), entitySubs(E1,q1)));
		U1 = unifyUnits(u0, u1);
		U2 = mergeUnits(U1, unifyUnits(unitSubs(U1,v0), unitSubs(U1,v1)));
		// append is voldoende
		//return substitution(mergeUnits(A0,U2),E2,());
		return substitution(A0+U2,E2,());
	}

	//println("unifying <pprint(x)> and <pprint(y)>");

	switch (<x,y>) {
		case <matrix(a,pu0,qv0), matrix(b,pu1,qv1)>:
			//return unifyMatrices(a,pu0,qv0, b,pu1,qv1, binding);
			return unifyMatrices(a,pu0,qv0, b,pu1,qv1);
		case <function(a,b), function(c,d)>: {
			S1 = unifyTypes(a,c);
			S2 = merge(S1, unifyTypes(typeSubs(S1,b),typeSubs(S1,d)));
			return S2;
			//<success, s1> = unifyTypes(a,c, binding);
			//if (!success) return <false, ident>;
			//<success, s2> = unifyTypes(b,d, s1);
			//if (!success) return <false, ident>;
			//return <true, s2>;
		}
		case <entity(a), entity(b)>: {
			//return unifyEntitiesLuxe(a, b, binding);
			return substitution((),unifyEntities(a, b),());
		}
		case <tupType([]), tupType([])>: {
			//return <true, binding>;
			return ident;
		}
		case <_,tupType([])>: {
			throw "Incorrect number of arguments";
		}
		case <tupType([]), _>: {
			throw "Incorrect number of arguments";
		}
		case <tupType(a), tupType(b)>: {
			S1 = unifyTypes(head(a),head(b));
			S2 = merge(S1,unifyTypes(typeSubs(S1,tupType(tail(a))),typeSubs(S1,tupType(tail(b)))));
			return S2;
			//<success, s1> = unifyTypes(head(a),head(b), binding);
			//if (!success) return <false, ident>;
			//<success, s2> = unifyTypes(typeSubs(s1,tupType(tail(a))),typeSubs(s1,tupType(tail(b))), s1);
			//if (!success) return <false, ident>;
			//return <true, merge(s1,s2)>;
		}
		case <listType(a), listType(b)>: {
			return unifyTypes(a,b);
			//<success, s1> = unifyTypes(a,b, binding);
			//if (!success) return <false, ident>;
			//return <true, s1>;
		}
		case <setType(a), setType(b)>: {
			return unifyTypes(a,b);
			//<success, s1> = unifyTypes(a,b, binding);
			//if (!success) return <false, ident>;
			//return <true, s1>;
		}
		case <boolean(), boolean()>: {
			//return <true, ident>;
			return ident;
		}
		case <typeVar(a), typeVar(a)>: {
			//return <true, binding>;
			return ident;
		}
		case <typeVar(a), Type b>: {
			return unifyVar(a,b);
		}
		case <Type a, typeVar(b)>: {
			return unifyVar(b,a);
		}
		default: {
			throw "Cannot unify types <pprint(x)> and <pprint(y)> <x> <y>";
		}
	}
}


module units::unification

import units::units;

import Map;
import Set;
import List;

import IO;

alias UnitBinding = map[str, Unit];
  
public Unit unitSubs(UnitBinding b, Unit un) {
	return mapUnit(Unit(Unit u) {
		switch (u) {
			case unitVar(x): return (x in b ? unitSubs(b,b[x]): u);
			default: return u;
		}		  
	}, un);
} 

public UnitBinding mergeUnits(UnitBinding bindingX, UnitBinding bindingY) {
	return (x: subs |
	        x <- bindingX,
	        subs := unitSubs(bindingY, bindingX[x]),
	        notIsVar(subs,x)) + bindingY;
}


public bool notIsVar(t,v) {
	switch (t) {
	case unitVar(x): return x != v;
	default: return true; 
	}
}

public UnitBinding unifyUnits(Unit u1, Unit u2) {
 
	UnitBinding unify(Unit unit) {
		vars = filterUnit(bool (Unit u) {return u is unitVar;}, unit);
    	nonVars = filterUnit(bool (Unit u) {return !(u is unitVar);}, unit);
     	nrVars = size(bases(vars));
    	if (nrVars == 0) {
    		if (size(bases(nonVars)) == 0) {
      			return ();
      		} else {
      			error = "unit failure: <pprint(u1)> vs <pprint(u2)>";
      			throw error;
      		}
    	} else {
      		Unit minBase = minBase(vars);
      		unitVar(name) = minBase;
			minp = power(unit, minBase);      		
	      	if (nrVars == 1) {
	       		if (bases(nonVars) == {} || 
	       			all(Unit x <- bases(nonVars),
	       		    	power(unit, x) % minp == 0)) {
	           		return (name: raise(nonVars, -1 / minp));
	       		} else {
	       			error = "unit failure: <pprint(unitSubs(b,u1))> vs <pprint(unitSubs(b,u2))>";
	       			throw error;
	       		}
	      	} else {
	      		Unit subst = uno();
	      		for (base <- bases(unit)) {
	      			if (base != minBase) {
	      				p = floor(power(unit, base), power(unit, minBase));
	      				subst = multiply(subst, raise(base, -p));
	      			}
	      		}
	      		b = (name: subst);
	      		return mergeUnits(unify(unitSubs(b, unit)), b);
	      	}
    	}
	}
	return unify(multiply(u1, reciprocal(u2)));
}

private Unit minBase(Unit metas) {
	private int f(base) = abs(power(metas, base));
	baseList = [b | b <- bases(metas)];
	return (head(baseList) | (f(it) > f(x)) ? x : it | x <- baseList);
}

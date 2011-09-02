module units::unification

import units::units;

import Map;
import Set;
import List;


alias UnitBinding = map[str, Unit];
  
public Unit unitSubs(UnitBinding b, Unit un) {
	return mapUnit(Unit(Unit u) {
		switch (u) {
			case unitVar(x): return (x in b ? unitSubs(b, b[x]): u);
			default: return u;
		}		  
	}, un);
} 

public UnitBinding mergeUnits(UnitBinding bindingX, UnitBinding bindingY) {
	return (x: unitSubs(bindingY, bindingX[x]) | x <- bindingX) + bindingY;
}

public set[str] unitVariables(u) = {x | /unitVar(x) <- u};

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

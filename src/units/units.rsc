module units::units

import Map;
import Set;
import List;
import IO;
import util::Math;

////////////////////////////////////////////////////////////////////////////////
// Required mathematical functions

//public real abs(real x) = (x < 0.0) ? -x : x;
//public int abs(int x) = (x < 0) ? -x : x;  

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
// Units

alias NamedUnitRef = int;

public map[NamedUnit,Unit] named2ref = ();
public map[NamedUnitRef,NamedUnit] ref2named = ();
public int namedCounter = 0;

data NamedUnit = aux_named(str name, str symbolic, Unit definition);

public Unit named(str name, str symbolic, Unit definition){
  a = aux_named(name, symbolic, definition);
  return makeNamedUnitRef(a);
}

public Unit makeNamedUnitRef(NamedUnit nu) {
   if(named2ref[nu]?){
      return named2ref[nu];
   }
   namedCounter += 1;
   named2ref[nu] = namedUnitRef(namedCounter);
   ref2named[namedCounter] = nu;
   return namedUnitRef(namedCounter);
}

alias Powers = map[Unit units, int powers];

data Prefix
  = prefix(str symbolic, real factor)
  ; 

//public map[str,Unit] varNames = ();
//public int varNameCounter = 0;
//
//public Unit unitVar(str name){
//   if(varNames[name]?)
//      return varNames[name];
//   varNameCounter += 1;
//   varNames[name] = unitVarRef(varNameCounter);
//   return unitVarRef(varNameCounter);
//}

data Unit
  = self()
  | namedUnitRef(int n)
  | scaled(Unit unit, Prefix prefix)
  | powerProduct(Powers powers, real factor)
  | unitVar(str name)
  | compoundUnit(list[Unit])
  ;

//data AtomicUnit
//  = namedUnit(str name, str symbolic)
//  | scaledUnit(AtomicUnit unit, Prefix prefix)
//  | derivedUnit(str name, str symbolic, Unit definition)
//  ;
//  
//
//data Unit 
//  = powerProduct(Powers powers, real factor)
//  ;
//  
//data AtomicUnit
//  = unitVar(str name)
//  | compoundUnit(list[Unit])
//  ;
  
public set[Unit] bases(powerProduct(Powers ps, real _)) = domain(ps);
  
//public int power(powerProduct(powers, _), Unit base) = powers[base] ? 0;
//public default int power(Unit u, Unit base) = (u==base) ? 1 : 0;

/// Memo version of power function

map[tuple[Unit,Unit], int] powerCache = ();

public int power(Unit u, Unit base) {
     ub = <u, base>;
     return powerCache[ub] ? power1(u, base, ub);
     //return power1(u, base, ub);
}

int power1(Unit u, Unit base, tuple[Unit,Unit] ub) {
    r = 0;
    if(u == base){
       r = 1;
    } else
	if (u is powerProduct) {
		r = (base in u.powers) ? u.powers[base] : 0;
	}
	powerCache[ub] = r;
	return r;
}

//public real factor(powerProduct(_, x), Unit base) = x;
public real factor(powerProduct(_, x)) = x;
  
public default set[Unit] bases(Unit u) = {u};


public default real factor(Unit _) = 1.0;

public set[str] unitVariables(/*Unit*/ u) = {x | /unitVar(str x) <- u};

//public Unit powerProduct(powers, 1.0) {
//  if (size(powers) == 1, u <- powers, powers[u] == 1) {
//    return u;
//  }
//  fail;
//}

public Unit normalizePowerProduct(Unit unit) {
	switch (unit) {
	case powerProduct(powers, 1.0): {
		//if (size(powers) == 1, u <- powers, powers[u] == 1) {
		if (size(powers) == 1, [<u, 1>] := toList(powers)) {
    		return u;
  		} else {
  			return unit;
  		}
	}
	default: return unit;
	}
}
    
public Unit multiply(Unit u1, Unit u2) =
 normalizePowerProduct(  
  powerProduct((base: p | base <- bases(u1) + bases(u2), 
                          p := power(u1, base) + power(u2, base), 
                          p != 0), 
               factor(u1) * factor(u2)));

public Unit raise(Unit u, int pwr) =
 normalizePowerProduct(   
  powerProduct((b: p | b <- bases(u),
                       p := pwr * power(u, b),
                       p != 0),
               expt(factor(u), pwr)));

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

public Unit foldUnit(Unit(Unit) baseFun, Unit(Unit, Unit) productFun, Unit(Unit) inverse, Unit unit, Unit init) {
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
		case named(_,x,_): return x;
		case scaled(x,prefix(p,f)): return "<p>:<pprint(x)>";
		//case unitVar(x): return "\'<x>";
		case unitVar(x): return x;
		case powerProduct(p, f): {
			front = ((f == 1.0) ? [] : ["<f>"] |
					 it + ["<pprint(x)><(p[x] == 1) ? "" : "^<p[x]>">"]	|
					 x <- p,p[x]>0);
			rear = ([] |
					 it + ["<pprint(x)><(p[x] == -1) ? "" : "^<-p[x]>">"]	|
					 x <- p,p[x]<0);
			//return ((front == []) ? "1" : (head(front) | it + "·" + x | x <- tail(front))) +
				   //((rear == []) ? "" : ("/" + head(rear) | it + "·" + x | x <- tail(rear)));
			return ((front == []) ? "1" : (head(front) | it + "*" + x | x <- tail(front))) +
				   ((rear == []) ? "" : ("/" + head(rear) | it + "*" + x | x <- tail(rear)));
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

public str serial(Unit u) {
	switch (u) {
	    case namedUnitRef(n): return ref2named[n].name;
		case named(x,_,_): return x;
		case scaled(x,prefix(p,f)): return "(<p> <serial(x)>)";
		//case unitVar(x): return "\'<x>";
		case powerProduct(p, f): {
			front = ((f == 1.0) ? "1" : "<f>" |
					 it + "*<serial(x)>^<p[x]>" |
					 x <- p);
			return "<front>";				  
		}
		case compoundUnit([]): {
			return "1";
		}
		case compoundUnit(units): {
			return (serial(head(units)) | "<it>,<serial(x)>" | x <- tail(units));
		}
	} 
	
	throw "serial does not implement: <u>";
} 

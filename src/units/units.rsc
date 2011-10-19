module units::units

import Map;
import Set;
import List;

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
// Units

alias Powers = map[Unit units, int powers];

data Unit
  = unitVar(str name)
  | self()
  | named(str name, str symbolic, Unit definition)
  | scaled(Unit unit, Prefix prefix)
  | powerProduct(Powers powers, real factor)
  | compoundUnit(list[Unit])
  ;
  
data Prefix
  = prefix(str symbolic, real factor)
  ; 
  
public set[Unit] bases(powerProduct(Powers ps, real _)) = ps.units;
  
//public int power(powerProduct(powers, _), Unit base) = powers[base] ? 0;
//public int power(Unit u, u) = 1;
//public default int power(Unit _, Unit _) = 0;

public int power(Unit u, Unit base) {
	if (u is powerProduct) {
		return (base in u.powers) ? u.powers[base] : 0;
	} else {
		return (u==base) ? 1 : 0;
	}
}

//public real factor(powerProduct(_, x), Unit base) = x;
public real factor(powerProduct(_, x)) = x;
  
public default set[Unit] bases(Unit u) = {u};


public default real factor(Unit _) = 1.0;

public set[str] unitVariables(u) = {x | /unitVar(x) <- u};

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
		case scaled(x,prefix(p,f)): return "(<p> <pprint(x)>)";
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
} 

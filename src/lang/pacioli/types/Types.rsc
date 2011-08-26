module lang::pacioli::types::Types

import Map;
import IO;

data MatrixType 
  = matrixType(Unit factor, IndexType rowType, IndexType columnType)
  ;

data IndexType 
  = indexType(EntityType entity, Unit unit)
  ;

data EntityType
  = compound(list[EntityType] types)
  | simple(str name)
  ;
  
  
alias Powers = map[Unit units, int powers];

data Unit
  = named(str symbolic, Unit definition)
  | self()
  | scaled(Unit namedUnit, Prefix prefix)
  | variable(str name)
  | powerProduct(Powers powers, real factor)
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

public Unit ONE() = powerProduct((), 1.0);


public &T foldUnit(&T(Unit) baseFun, &T(&T, &T) productFun, &T(&T) inverse, Unit unit, &T init) {
  lst = [];
  for (x <- bases(unit)) {
	  base = baseFun(x);
	  pwr = power(x, unit);
	  elt = (pwr < 0) ? inverse(base) : base;
	  lst += [  elt | _ <- [1..abs(pwr)]];
	  println("LST = <lst>");
	  println("BASES(u): <bases(unit)>");
  }
  return ( init | productFun(it, x) | x <- lst );
}

public real abs(real x) = (x < 0.0) ? -x : x;
public int abs(int x) = (x < 0) ? -x : x;  

public Unit mapUnit(Unit(Unit) fn, Unit unit) = foldUnit(fn, multiply, reciprocal, unit, ONE());

public Unit filterUnit(bool(Unit) fn, Unit unit) = 
  mapUnit(Unit(Unit u) { return (fn(u)) ? u : ONE(); }, unit);
    
public Unit multiply(Unit u1, Unit u2) =  powerProduct(
       (base: p | base <- bases(u1) + bases(u2), p := power(u1, base) + power(u2, base), p != 0), 
         factor(u1) * factor(u2));

public Unit divide(Unit u1, Unit u2) = multiply(u1, raise(u2,-1));

public Unit reciprocal(Unit u) = raise(u,-1);

private real expt(real x, int e) {
  if (e == 0) {
    return 1.0;
  }
  if (e < 0) {
    return 1 / expt(x, -e);
  }
  return x * expt(x, e  - 1);
}

public Unit raise(Unit u, int pwr) = 
  powerProduct((b: p | b <- bases(u), p := pwr * power(u, b), p != 0), expt(factor(u), pwr));

alias Binding = map[str, Unit];

public bool unitLess (Unit u) = bases(u) != {};

public tuple[bool, Binding] unifyUnits(Unit u1, Unit u2) { 
  tuple[bool, Binding] unify(Unit unit) {
    metas = filterUnit(bool (Unit u) {return u is variable;}, unit);
    nonMetas = filterUnit(bool (Unit u) {return !(u is variable);}, unit);
    if (unitLess(metas)) {
    	return <unitLess(nonMetas), ()>;
    } else {
      int m = size(bases(metas));
      if (m == 1) {
       if (all(power(x, unit) % power(y, unit) == 0, x <- bases(metas), y <- bases(nonMetas))) {
         if (head <- bases(metas)) {
           return ( head : raise(nonMetas, -1 / power(head, unit)) );
         }
       }
       else {
         return <false, ()>;
       }
      } else {
         U = complicateSubst;
         <success, S> = unify(apply(U, unit));
         if (success) {
           return compose(S, U);
         }
         return <false, ()>;
      }
    }
    
    
    println(metas);
    println(nonMetas);
    return <true, ()>;
  }
  
  return unify(multiply(u1, raise(u2, -1)));
	
}



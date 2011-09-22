module lang::pacioli::types::inference

import Map;
import Set;
import List;
import IO;

import units::units;
import units::unification;

import lang::pacioli::ast::KernelPacioli;
import lang::pacioli::utils::Implode;
import lang::pacioli::types::Types;
import lang::pacioli::types::unification;

int glbcounter = 0;

str fresh(str x) {glbcounter += 1; return "<x><glbcounter>";}

alias Environment = map[str, Scheme];

public Environment envSubs(Substitution s, Environment e) {
	return (key: schemeSubs(s, e[key]) | key <- e);
}

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


public list[str] glbstack = [];

public tuple[Type, Substitution] inferTypeAPI(Expression exp, Environment assumptions) {
	try {
		glbcounter = 0;
		glbstack = [];
		return inferType(exp,assumptions);
	} catch err: {
		throw("\nType error: <err>\n\nStack:<("" | "<it>\n<frame>" | frame <- glbstack)>");
	}
}

public tuple[Type, Substitution] inferType(Expression exp, Environment assumptions) {
	push("<pprint(exp)>");
	switch (exp) {
		case variable(x): {
			typ = instScheme(assumptions[x]);
			pop("<pprint(typ)>");
			return <typ, ident>;
		}
		case const(0.0): {
			typ = matrix(unitVar(fresh("u")),duo(entityVar(fresh("E")),unitVar(fresh("u"))),duo(entityVar(fresh("E")),unitVar(fresh("u")))); // todo
			pop("<pprint(typ)>");
			return <typ, ident>;
		}
		case const(x): {
			typ = matrix(uno(),duo(compound([]),uno()),duo(compound([]),uno())); // todo
			pop("<pprint(typ)>");
			return <typ, ident>;
		}
		case tup([]): {
			return <tupType([]),ident>;
		}
		case tup(items): {
			types = [];
			subs = ident;
			for (x <- items) {
				<t, s> = inferType(x, envSubs(subs, assumptions));
				subs = merge(subs,s);
				types += [t];
			}
			typ = tupType(types);
			pop("<pprint(typ)>");
			return <typ, subs>;
		}
		case branch(c,x,y): {
			<condType, s0> = inferType(c, assumptions);
			<succ, s1> = unifyTypes(condType, boolean(), s0);
			s01 = merge(s0,s1);
			<xType, s2> = inferType(x, envSubs(s01, assumptions));
			s012 = merge(s01,s2);
			<yType, s3> = inferType(y, envSubs(s012, assumptions));
			s0123 = merge(s012,s3);
			<succ, s4> = unifyTypes(typeSubs(s0123, xType), typeSubs(s0123, yType), s0123);
			s01234 = merge(s0123,s4);
			typ = typeSubs(s01234, yType);
			return <typ,s01234>;
		}
		case and(x,y): {
			<xType, s0> = inferType(x, assumptions);
			<yType, s1> = inferType(y, envSubs(s0, assumptions));
			s01 = merge(s0,s1);
			<succ, s2> = unifyTypes(xType, boolean(), s01);
			s012 = merge(s01,s2);
			<succ, s3> = unifyTypes(yType, boolean(), s012);
			s0123 = merge(s012,s3);
			typ = boolean();
			return <typ,s0123>;
		}
		case or(x,y): {
			<xType, s0> = inferType(x, assumptions);
			<yType, s1> = inferType(y, envSubs(s0, assumptions));
			s01 = merge(s0,s1);
			<succ, s2> = unifyTypes(xType, boolean(), s01);
			s012 = merge(s01,s2);
			<succ, s3> = unifyTypes(yType, boolean(), s012);
			s0123 = merge(s012,s3);
			typ = boolean();
			return <typ,s0123>;
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
				// never reached because an exception is thrown instead of a false return value
				throw("\nType error: \n\nStack:<("" | "<it>\n<frame>" | frame <- glbstack)>");
			}
		}
		case let(var,val,body): {
			<t1, s1> = inferType(val, assumptions);
			as = envSubs(s1,assumptions);
			assumedUnitVars = {y | x <- as, y <- unitVariables(as[x])};
			assumedEntityVars = {y | x <- as, y <- entityVariables(as[x])};
			assumedTypeVars = {y | x <- as, y <- typeVariables(as[x])};						
			scheme = forall(unitVariables(t1) - assumedUnitVars,
							entityVariables(t1) - assumedEntityVars,
							typeVariables(t1) - assumedTypeVars,
							t1);
			//println("<pprint(exp)>\n scheme=<scheme>");
			bound = as + (var: scheme);			
			<t2, s2> = inferType(body, envSubs(s1,bound));
			s12 = merge(s1,s2);
			typ = t2;
			pop("<pprint(typ)>");
			return <typ, s12>;
		}
		case abstraction(vars,body): {
			betas = [<x,fresh(x)> | x <- vars];
			bound = (assumptions | it + (v: forall({},{},{},typeVar(b))) | <v,b> <- betas);			
			<t1, s1> = inferType(body, bound);
			typ = typeSubs(s1,function(tupType([typeVar(b) | <_,b> <- betas]), t1));
			pop("<pprint(typ)>");
			return <typ, s1>;
		}
		default: throw "Unknown expression: <exp>";
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


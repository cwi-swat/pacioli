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


public list[str] glbstack = [];

int glbcounter = 100;

str fresh(str x) {glbcounter += 1; return "<x><glbcounter>";}

public tuple[Type, Substitution] inferTypeAPI(Expression exp, Environment lib) {
	try {
		glbcounter = 100;
		glbstack = [];
		return inferType(exp,lib,());
	} catch err: {
		throw("\nType error: <err>\n\nStack:<("" | "<it>\n<frame>" | frame <- glbstack)>");
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
// 

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


public tuple[Type, Substitution] inferType(Expression exp, Environment lib, Environment assumptions) {
	push("<pprint(exp)>");
	switch (exp) {
		case variable(x): {
			typ = instScheme(assumptions[x] ? lib[x]);
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
			s = ident;
			for (x <- items) {
				<t, s> = inferType(x, lib, envSubs(s, assumptions));
				subs = merge(subs,s);
				types += [t];
			}
			typ = tupType(types);
			pop("<pprint(typ)>");
			return <typ, subs>;
		}
		case branch(c,x,y): {
			<condType, S0> = inferType(c, lib, assumptions);
			S1 = merge(S0, unifyTypes(condType, boolean()));
			<xType, T0> = inferType(x, lib, envSubs(S1, assumptions));
			S2 = merge(S1,T0);
			<yType, T1> = inferType(y, lib, envSubs(S2, assumptions));
			S3 = merge(S2,T1);
			S4 = merge(S3,unifyTypes(typeSubs(S3, xType), typeSubs(S3, yType)));
			typ = typeSubs(S4, yType);
			return <typ,S4>;
		}
		case and(x,y): {
			<xType, S0> = inferType(x, lib, assumptions);
			<yType, T0> = inferType(y, lib, envSubs(S0, assumptions));
			S1 = merge(S0,T0);
			S2 = merge(S1,unifyTypes(typeSubs(S1,xType), boolean()));
			S3 = merge(S2,unifyTypes(typeSubs(S2,yType), boolean()));
			typ = boolean();
			return <typ,S3>;
		}
		case or(x,y): {
			<xType, S0> = inferType(x, lib, assumptions);
			<yType, T0> = inferType(y, lib, envSubs(S0, assumptions));
			S1 = merge(S0,T0);
			S2 = merge(S1,unifyTypes(typeSubs(S1,xType), boolean()));
			S3 = merge(S2,unifyTypes(typeSubs(S2,yType), boolean()));
			typ = boolean();
			return <typ,S3>;
		}
		case application(x,y): {
			<funType, S0> = inferType(x, lib, assumptions);
			<argType, T0> = inferType(y, lib, envSubs(S0, assumptions));
			S1 = merge(S0,T0);
			beta = fresh("identifier");
			template = function(argType, typeVar(beta));
			T1 = unifyTypes(typeSubs(T0, funType), template);
			S2 = merge(S1, T1);
			typ = typeSubs(T1, typeVar(beta));
			pop("<pprint(typ)>");
			return <typ, S2>;
		}
		case let(var,val,body): {
			
			// hack for recursive functions
			f = fresh("letrec");
			assumptions = assumptions + (var: forall({},{},{},typeVar(f)));
			
			<t1, s1> = inferType(val, lib, assumptions);
			// is deze nodig???
			// as = envSubs(s1,assumptions);
			as = assumptions;
			assumedUnitVars = {y | x <- as, y <- unitVariables(as[x])};
			assumedEntityVars = {y | x <- as, y <- entityVariables(as[x])};
			assumedTypeVars = {y | x <- as, y <- typeVariables(as[x])};						
			scheme = forall(unitVariables(t1) - assumedUnitVars,
							entityVariables(t1) - assumedEntityVars,
							typeVariables(t1) - assumedTypeVars,
							t1);
			bound = as + (var: scheme);			
			<t2, s2> = inferType(body, lib, envSubs(s1,bound));
			s12 = merge(s1,s2);
			typ = t2;
			pop("<pprint(typ)>");
			return <typ, s12>;
		}
		case abstraction(vars,body): {
			betas = [<x,fresh(x)> | x <- vars];
			bound = (assumptions | it + (v: forall({},{},{},typeVar(b))) | <v,b> <- betas);			
			<t1, s1> = inferType(body, lib, bound);
			typ = typeSubs(s1,function(tupType([typeVar(b) | <_,b> <- betas]), t1));
			pop("<pprint(typ)>");
			return <typ, s1>;
		}
		default: throw "Unknown expression: <exp>";
	}
}


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
		case abstraction(x,b): {
			beta = fresh(x);
			<t1, s1> = inferType(b, assumptions+(x: forall({},{},{},typeVar(beta))));
			typ = typeSubs(s1,function(typeVar(beta), t1));
			pop("<pprint(typ)>");
			return <typ, s1>;
		}
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


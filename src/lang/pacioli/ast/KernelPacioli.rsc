module lang::pacioli::ast::KernelPacioli

import List;


data Expression = variable(str name)
				| const(real number)
				| constInt(int integer)
				| tup(list[Expression] items)
				| abstraction(list[str] vars, Expression body)
 				| application(Expression fn, Expression arg)
 				| branch(Expression cond, Expression pos, Expression neg)
 				| comprehension(Expression head, list[Expression] rest)
 				| someComprehension(Expression head, list[Expression] rest)
 				| allComprehension(Expression head, list[Expression] rest)
 				| countComprehension(Expression head, list[Expression] rest)
 				| sumComprehension(Expression head, list[Expression] rest)
 				| generator(str variable, Expression collection)
 				| bind(str variable, Expression exp)
 				| filt(Expression exp)
 				| equal(Expression lhs, Expression rhs)
 				| clos(Expression arg)
 				| kleene(Expression arg)
 				| mul(Expression lhs, Expression rhs)
 				| div(Expression lhs, Expression rhs)
 				| reci(Expression arg)
 				| sum(Expression lhs, Expression rhs)
 				| sub(Expression lhs, Expression rhs)
 				| neg(Expression arg)
 				| and(Expression lhs,Expression rhs)
 				| or(Expression lhs,Expression rhs)
 				| not(Expression arg)
 				| trans(Expression arg)
 				| joi(Expression lhs, Expression rhs);

public Expression normalize(Expression exp) {
	return innermost visit(exp) {
		case constInt(x) => const(x*1.0)
		case comprehension(x,y) => translateComprehension("list",x,y)
		case someComprehension(x,y) => translateComprehension("some",x,y)
		case allComprehension(x,y) => translateComprehension("all",x,y)
		case countComprehension(x,y) => translateComprehension("count",x,y)
		case sumComprehension(x,y) => translateComprehension("sum",x,y)
		case equal(x,y) => application(variable("equal"),tup([x,y]))
		case clos(x) => application(variable("closure"),tup([x]))
		case kleene(x) => application(variable("kleene"),tup([x]))
		case not(x) => application(variable("not"),tup([x]))
		case sum(x, y) => application(variable("sum"),tup([x,y]))
		case mul(x, y) => application(variable("multiply"),tup([x,y]))
		case sub(x, y) => application(variable("sum"),tup([x,normalize(neg(y))]))
		case div(x, y) => application(variable("multiply"),tup([x,normalize(reci(y))]))
		case joi(x, y) => application(variable("join"),tup([x,y]))
		case neg(x) => application(variable("negative"),tup([x]))
		case trans(x) => application(variable("transpose"),tup([x]))
		case reci(x) => application(variable("reciprocal"),tup([x]))
	}
}

public Expression translateComprehension(str kind, Expression header, list[Expression] parts) {
	<zero,unit,merge> = comprehensionTriple(kind); 
	if (parts == []) {
		return application(unit, tup([header]));
	} else {
		first = head(parts);
		switch (first) {
			case generator(var,exp):  
				return application(variable("reduce"), 
					tup([zero,
						 abstraction([var], translateComprehension(kind, header,tail(parts))),
						 merge, 
					     exp]));
			case bind(var,exp): {
				alt = [generator(var,application(unit,tup([exp])))] + tail(parts);
				return translateComprehension(kind,header,alt);
			}
			case filt(exp): 
				return branch(exp, translateComprehension(kind,header,tail(parts)), 
					zero);
		}
	}
}

tuple[Expression,Expression,Expression] comprehensionTriple(str kind) {
	switch (kind) {
		case "list": return <variable("empty"),variable("single"),variable("append")>;
		case "some": return <variable("false"),variable("identity"),abstraction(["x","y"],or(variable("x"),variable("y")))>;
		case "all": return <variable("true"),variable("identity"),abstraction(["x","y"],and(variable("x"),variable("y")))>;
		case "count": return <const(0.0),abstraction(["x"],const(1.0)),variable("sum")>;		
		case "sum": return <const(0.0),variable("identity"),variable("sum")>;
	}
}

public str pprint(Expression exp) {
	switch(exp) {
		case variable(x): return "<x>";
		case const(x): return "<x>";
		case tup([]): return "()";
		case tup(items): return "(<(pprint(head(items)) | it + "," + pprint(x) | x <- tail(items))>)";
		case abstraction(x,y): return "(lambda <pprint(tup([variable(v) | v <- x]))> <pprint(y)>)";	
		case application(x,y): return "<pprint(x)><pprint(y)>";
		case branch(c,x,y): return "if <pprint(c)> then <pprint(x)> else <pprint(y)> fi";
		case and(x,y): return "(<pprint(x)> && <pprint(y)>)";
		case or(x,y): return "(<pprint(x)> || <pprint(y)>)";
		case comprehension(h,r): return "[<pprint(h)>  | <(pprint(head(r)) | it + ", " + pprint(x) | x <- tail(r))>]";
		case someComprehension(h,r): return "some[<pprint(h)>  | <(pprint(head(r)) | it + ", " + pprint(x) | x <- tail(r))>]";
		case generator(x,y): return "<x> in <pprint(y)>";
		default: throw "no pprint for <exp>";
	}
}
 				
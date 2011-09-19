module lang::pacioli::ast::KernelPacioli

import List;


data Expression = variable(str name)
				| const(real number)
				| tup(list[Expression] items)
				| abstraction(list[str] vars, Expression body)
 				| application(Expression fn, Expression arg)
 				| comprehension(Expression head, list[Expression] rest)
 				| generator(str variable, Expression collection)
 				| equal(Expression lhs, Expression rhs)
 				| clos(Expression arg)
 				| mul(Expression lhs, Expression rhs)
 				| div(Expression lhs, Expression rhs)
 				| reci(Expression arg)
 				| sum(Expression lhs, Expression rhs)
 				| sub(Expression lhs, Expression rhs)
 				| neg(Expression arg)
 				| trans(Expression arg)
 				| joi(Expression lhs, Expression rhs);

public Expression normalize(Expression exp) {
	return innermost visit(exp) {
		case comprehension(x,y) => translateComprehension(x,y)
		case equal(x,y) => application(variable("equal"),tup([x,y]))
		case clos(x) => application(variable("closure"),tup([x]))
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

public Expression translateComprehension(Expression header, list[Expression] parts) {
	if (parts == []) {
		return application(variable("single"), tup([header]));
	} else {
		first = head(parts);
		switch (first) {
			case generator(var,exp): 
				return application(variable("iter"), tup([abstraction([var], translateComprehension(header,tail(parts))), exp]));
		}
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
		case comprehension(h,r): return "[<pprint(h)>  | <(pprint(head(r)) | it + ", " + pprint(x) | x <- tail(r))>]";
		case generator(x,y): return "<x> in <pprint(y)>";
		default: throw "no pprint for <exp>";
	}
}
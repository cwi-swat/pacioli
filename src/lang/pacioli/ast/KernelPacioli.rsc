module lang::pacioli::ast::KernelPacioli

import List;


data Expression = variable(str name)
				| const(real number)
				| tup(list[Expression] items)
				| abstraction(list[str] vars, Expression body)
 				| application(Expression fn, Expression arg)
 				| clos(Expression arg)
 				| mul(Expression lhs, Expression rhs)
 				| sum(Expression lhs, Expression rhs)
 				| sub(Expression lhs, Expression rhs)
 				| neg(Expression arg)
 				| trans(Expression arg)
 				| joi(Expression lhs, Expression rhs);

public Expression normalize(Expression exp) {
	return innermost visit(exp) {
	  case clos(x) => application(variable("closure"),tup([x]))
	  case sum(x, y) => application(variable("sum"),tup([x,y]))
	  case mul(x, y) => application(variable("multiply"),tup([x,y]))
	  case sub(x, y) => application(variable("sum"),tup([x,normalize(neg(y))]))
	  case joi(x, y) => application(variable("join"),tup([x,y]))
	  case neg(x) => application(variable("negative"),tup([x]))
	  case trans(x) => application(variable("transpose"),tup([x]))
	}
}

public Expression sum(Expression lhs, Expression rhs) = application(variable("sum"),tup([lhs,rhs]));

public str pprint(Expression exp) {
	switch(exp) {
		case variable(x): return "<x>";
		case tup([]): return "()";
		case tup(items): return "(<(pprint(head(items)) | it + "," + pprint(x) | x <- tail(items))>)";
		case abstraction(x,y): return "(lambda <pprint(tup([variable(v) | v <- x]))> <pprint(y)>)";	
		case application(x,y): return "<pprint(x)><pprint(y)>";
		default: throw "no pprint for <exp>";
	}
}
module lang::pacioli::ast::KernelPacioli

import List;


data Expression = variable(str name)
				| const(real number)
				| tup(list[Expression] items)
				| abstraction(list[str] vars, Expression body)
 				| application(Expression fn, Expression arg);

public str pprint(Expression exp) {
	switch(exp) {
		case variable(x): return "<x>";
		case tup([]): return "()";
		case tup(items): return "(<(pprint(head(items)) | it + "," + pprint(x) | x <- tail(items))>)";
		case abstraction(x,y): return "lambda <pprint(tup([variable(v) | v <- x]))> <pprint(y)>";	
		case application(x,y): return "<pprint(x)><pprint(y)>";
		default: throw "no pprint for <exp>";
	}
}
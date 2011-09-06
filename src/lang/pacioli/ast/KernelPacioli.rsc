module lang::pacioli::ast::KernelPacioli

import List;

////////////////////////////////////////////////////////////////////////////////
// Expressions

data Expression = variable(str name)
				| const(real number)
				| tup(list[Expression] items)
                | pair2(Expression first, Expression second)
				| abstraction(list[str] vars, Expression body)
 				| application(Expression fn, Expression arg);

public str pprint(Expression exp) {
	switch(exp) {
		case variable(x): return "<x>";
		case tup([]): return "()";
		case tup(items): return "(<(pprint(head(items)) | it + "," + pprint(x) | x <- tail(items))>)";
		case pair2(x,y): return "(<pprint(x)>,<pprint(y)>)";
		case abstraction(x,y): return "lambda <pprint(tup([variable(v) | v <- x]))> <pprint(y)>";	
		case application(x,pair2(y,z)): return "<pprint(x)><pprint(pair2(y,z))>";	
		case application(x,y): return "<pprint(x)><pprint(y)>";
		default: throw "no pprint for <exp>";
	}
}
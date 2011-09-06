module lang::pacioli::ast::KernelPacioli

////////////////////////////////////////////////////////////////////////////////
// Expressions

data Expression = variable(str name)
				| const(real number)
                | pair2(Expression first, Expression second)
				| abstraction(str var, Expression body)
 				| application(Expression fn, Expression arg);

public str pprint(Expression exp) {
	switch(exp) {
		case variable(x): return "<x>";
		case pair2(x,y): return "(<pprint(x)>,<pprint(y)>)";
		case abstraction(x,y): return "lambda <x> <pprint(y)>";	
		case application(x,pair2(y,z)): return "<pprint(x)><pprint(pair2(y,z))>";	
		case application(x,y): return "<pprint(x)>(<pprint(y)>)";
		default: throw "no pprint for <exp>";
	}
}
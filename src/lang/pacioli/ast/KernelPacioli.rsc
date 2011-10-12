module lang::pacioli::ast::KernelPacioli

import List;


anno loc Expression@location;


data Expression = variable(str name)
				| bang(str ent, str unit)
				| const(real number)
				| constInt(int integer)
				| setConstr(list[Expression] items)
				| lis(list[Expression] items)
				| tup(list[Expression] items)
				| abstraction(list[str] vars, Expression body)
 				| application(Expression fn, Expression arg)
 				| llet(list[Binding] bindings, Expression body)
 				| let(str var, Expression val, Expression body)
 				| letLuxe(str var, list[str] vars, Expression val, Expression body)
 				| letSuperLuxe(list[str] vars, Expression val, Expression body)
 				| branch(Expression cond, Expression pos, Expression neg)
 				| comprehension(Expression head, list[Expression] rest)
 				| someComprehension(Expression head, list[Expression] rest)
 				| allComprehension(Expression head, list[Expression] rest)
 				| countComprehension(Expression head, list[Expression] rest)
 				| sumComprehension(Expression head, list[Expression] rest)
 				| setComprehension(Expression head, list[Expression] rest)
 				| gcdComprehension(Expression head, list[Expression] rest)
 				// todo: interesting vec comprehension
 				| vecComprehension(str row, str column, Expression head, list[Expression] rest)
 				| generator(str variable, Expression collection)
 				| generatorLuxe(list[str] vars, Expression collection)
 				//| matrixGenerator(str variable, Expression collection)
				| matrixGenerator(str row, str column, Expression collection)
				| setGenerator(str variable, Expression collection)
 				| bind(str variable, Expression exp)
 				| bindLuxe(list[str] vars, Expression exp)
 				| filt(Expression exp)
 				| equal(Expression lhs, Expression rhs)
 				| lesseq(Expression lhs, Expression rhs)
 				| less(Expression lhs, Expression rhs)
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
 				| implies(Expression lhs,Expression rhs)
 				| not(Expression arg)
 				| trans(Expression arg)
 				| per(Expression lhs, Expression rhs)
 				| joi(Expression lhs, Expression rhs);

data Binding
	= simpleBinding(str var, Expression val)
	| functionBinding(str fn, list[str] args, Expression body)
	| tupleBinding(list[str] vars, Expression val);
	
private Expression oneLet(Binding binding, Expression body) {
	switch (binding) {
	case simpleBinding(var, val): 
		return let(var,val,body);
	case functionBinding(var, vars, val): 
		return let(var, abstraction(vars,val), body);
	case tupleBinding(vars, val): 
		return application(variable("apply"), tup([abstraction(vars,body), val]));
	}
}

public Expression normalize(Expression exp) {
	return innermost visit(exp) {
		case vecComprehension(row,column,x,y) => 
		normalize(
				application(variable("matrixFromTuples"), 
							tup([setComprehension(application(variable("tuple"), 
																tup([variable(row), variable(column), x])),
								 				  y)])))
		case variable("_") => variable(fresh("_"))
		case llet([], body) => body
		case llet(xs, body) => oneLet(head(xs), normalize(llet(tail(xs), body)))
	    //case e:letSuperLuxe(vars,val,body) => application(variable("apply"), tup([abstraction(vars,body), val]))[@location=e@location]
	    case letSuperLuxe(vars,val,body) => application(variable("apply"), tup([abstraction(vars,body), val]))
		case letLuxe(var,vars,val,body) => let(var,abstraction(vars,val),body)
		case lis([]) => variable("emptyList")
		case lis(xs) => (application(variable("singletonList"), tup([head(xs)])) |
						 application(variable("append"), 
						 			 tup([it, application(variable("singletonList"), tup([x]))])) | 
						 x <- tail(xs))
		case setConstr(xs) => (application(variable("singletonSet"), tup([head(xs)])) |
						 application(variable("union"), 
						 			 tup([it, application(variable("singletonSet"), tup([x]))])) | 
						 x <- tail(xs))
		case constInt(x) => const(x*1.0)
		case comprehension(x,y) => translateComprehension("list",x,y)
		case someComprehension(x,y) => translateComprehension("some",x,y)
		case allComprehension(x,y) => translateComprehension("all",x,y)
		case countComprehension(x,y) => translateComprehension("count",x,y)
		case sumComprehension(x,y) => translateComprehension("sum",x,y)
		case vecComprehension(x,y) => translateComprehension("vec",x,y)
		case gcdComprehension(x,y) => translateComprehension("gcd",x,y)
		case setComprehension(x,y) => translateComprehension("set",x,y)
		case equal(x,y) => application(variable("equal"),tup([x,y]))
		case lesseq(x,y) => application(variable("lessEq"),tup([x,y]))
		case less(x,y) => application(variable("less"),tup([x,y]))
		case clos(x) => application(variable("closure"),tup([x]))
		case kleene(x) => application(variable("kleene"),tup([x]))
		case not(x) => application(variable("not"),tup([x]))
		case implies(x, y) => normalize(or(application(variable("not"),tup([x])),y))
		case sum(x, y) => application(variable("sum"),tup([x,y]))
		case mul(x, y) => application(variable("multiply"),tup([x,y]))
		case sub(x, y) => application(variable("sum"),tup([x,normalize(neg(y))]))
		case div(x, y) => application(variable("multiply"),tup([x,normalize(reci(y))]))
		case joi(x, y) => application(variable("join"),tup([x,y]))
		case per(x, y) => application(variable("join"),
		                              tup([x, application(variable("reciprocal"),
		                                                  tup([application(variable("transpose"),
		                                                                   tup([y]))]))]))
		case neg(x) => application(variable("negative"),tup([x]))
		case trans(x) => application(variable("transpose"),tup([x]))
		case reci(x) => application(variable("reciprocal"),tup([x]))
	}
}

public Expression translateComprehension(str kind, Expression header, list[Expression] parts) {
	switch(kind) {
	case "list":
		return translateComprehensionRec(kind, variable("emptyList"), variable("addMut"), header, parts);
	case "set":
		return translateComprehensionRec(kind, variable("emptySet"), variable("adjoinMut"), header, parts);		
	case "sum":
		return translateComprehensionRec(kind, const(0.0), variable("whocares"), header, parts);
	case "count":
		return translateComprehensionRec(kind, const(0.0), variable("whocares"), header, parts);		
	case "some":
		return translateComprehensionRec(kind, variable("false"), abstraction(["x","y"], or(variable("x"), variable("y"))), header, parts);
	case "gcd":
		return translateComprehensionRec(kind, const(0.0), variable("whocares"), header, parts);
	case "all":
		return translateComprehensionRec(kind, variable("true"), abstraction(["x","y"], and(variable("x"), variable("y"))), header, parts);		
	}
}

public Expression mergeBody (str kind, Expression x, Expression y) {
	switch(kind) {
	case "list":
		return application(variable("addMut"), tup([x,y]));
	case "set":
		return application(variable("adjoinMut"), tup([x,y]));		
	case "some":
		return or(x,y);
	case "all":
		return and(x,y);
	case "count":
		return application(variable("sum"), tup([x,const(1.0)]));
	case "gcd":
		return application(variable("gcd"), tup([x,y]));		
	case "sum":
		return application(variable("sum"), tup([x,y]));		
	}
}

int glbcounter = 100;

str fresh(str x) {glbcounter += 1; return "<x><glbcounter>";}

public Expression translateComprehensionRec(str kind, Expression zero, Expression merge, Expression header, list[Expression] parts) {
	if (parts == []) {
		return mergeBody(kind, zero, header);
		
	} else {
		first = head(parts);
		switch (first) {
			case generator(var,exp):
				return translateGenerator(kind, var, exp, zero, merge, header, parts);
			case generatorLuxe(vars,exp): {
				var = fresh("tup");
				return translateComprehensionRec(kind, zero, merge, header, [generator(var,exp), bindLuxe(vars, variable(var))] + tail(parts));
			}
			case setGenerator(var,exp):
				return translateSetGenerator(kind, var, exp, zero, merge, header, parts);				
			case matrixGenerator(row,col,exp):
				return translateMatrixGenerator(kind, row, col, exp, zero, merge, header, parts);
			case filt(exp): 
				return branch(exp, translateComprehensionRec(kind, zero, merge, header,tail(parts)), zero);
			case bind(var,exp): {
				return application(abstraction([var], translateComprehensionRec(kind, zero, merge, header,tail(parts))), tup([exp]));
			}
			case bindLuxe(vars,exp): {
				return application(variable("apply"), tup([abstraction(vars, translateComprehensionRec(kind, zero, merge, header,tail(parts))), exp]));
			}
			default: {
				error = "oeps <first>";
				throw error;
			}
		}
	}
}

Expression translateGenerator(str kind, str var, Expression exp, Expression zero, Expression merge, Expression header, list[Expression] parts) {
	return application(variable("loopList"), 
					   tup([zero,
						    //variable("identity"),
						    abstraction(["accu",var], 
  	                                    translateComprehensionRec(kind, variable("accu"), merge, header, tail(parts))), 
					        exp]));
}

Expression translateSetGenerator(str kind, str var, Expression exp, Expression zero, Expression merge, Expression header, list[Expression] parts) {
	return application(variable("reduceSet"), 
					   tup([zero,
						    variable("identity"),
						    abstraction(["accu",var], 
  	                                    translateComprehensionRec(kind, variable("accu"), merge, header, tail(parts))), 
					        exp]));
}

Expression translateMatrixGenerator(str kind, str row, str col, Expression exp, Expression zero, Expression merge, Expression header, list[Expression] parts) {
	return application(variable("loopMatrix"), 
					   tup([zero,
						    abstraction(["accu",row,col], 
  	                                    translateComprehensionRec(kind, variable("accu"), merge, header, tail(parts))), 
					        exp]));
}

public str pprint(Expression exp) {
	switch(exp) {
		case variable(x): return "<x>";
		case bang(x,y): return "<x>!<y>";
		case const(x): return "<x>";
		case tup([]): return "()";
		case tup(items): return "(<(pprint(head(items)) | it + ", " + pprint(x) | x <- tail(items))>)";
		case abstraction(x,y): return "(lambda <pprint(tup([variable(v) | v <- x]))> <pprint(y)>)";	
		case application(x,y): return "<pprint(x)><pprint(y)>";
		case let(v,x,y): return "(let <v> = <pprint(x)> in <pprint(y)>)";
		case branch(c,x,y): return "if <pprint(c)> then <pprint(x)> else <pprint(y)> fi";
		case and(x,y): return "(<pprint(x)> && <pprint(y)>)";
		case or(x,y): return "(<pprint(x)> || <pprint(y)>)";
		case comprehension(h,r): return "[<pprint(h)>  | <(pprint(head(r)) | it + ", " + pprint(x) | x <- tail(r))>]";
		case someComprehension(h,r): return "some[<pprint(h)>  | <(pprint(head(r)) | it + ", " + pprint(x) | x <- tail(r))>]";
		case generator(x,y): return "<x> in <pprint(y)>";
		default: throw "no pprint for <exp>";
	}
}
 				
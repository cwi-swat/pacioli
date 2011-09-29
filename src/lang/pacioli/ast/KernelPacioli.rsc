module lang::pacioli::ast::KernelPacioli

import List;


data Expression = variable(str name)
				| const(real number)
				| constInt(int integer)
				| setConstr(list[Expression] items)
				| lis(list[Expression] items)
				| tup(list[Expression] items)
				| abstraction(list[str] vars, Expression body)
 				| application(Expression fn, Expression arg)
 				| let(str var, Expression val, Expression body)
 				| letLuxe(str var, list[str] vars, Expression val, Expression body)
 				| branch(Expression cond, Expression pos, Expression neg)
 				| comprehension(Expression head, list[Expression] rest)
 				| someComprehension(Expression head, list[Expression] rest)
 				| allComprehension(Expression head, list[Expression] rest)
 				| countComprehension(Expression head, list[Expression] rest)
 				| sumComprehension(Expression head, list[Expression] rest)
 				| setComprehension(Expression head, list[Expression] rest)
 				// todo: interesting vec comprehension
 				//| vecComprehension(Expression head, list[Expression] rest)
 				| generator(str variable, Expression collection)
 				//| matrixGenerator(str variable, Expression collection)
				| matrixGenerator(str row, str column, Expression collection)
				| setGenerator(str variable, Expression collection)
 				| bind(str variable, Expression exp)
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
 				| not(Expression arg)
 				| trans(Expression arg)
 				| joi(Expression lhs, Expression rhs);

public Expression normalize(Expression exp) {
	return innermost visit(exp) {
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
		case comprehension(x,y) => translateComprehension2("list",x,y)
		case someComprehension(x,y) => translateComprehension2("some",x,y)
		case allComprehension(x,y) => translateComprehension2("all",x,y)
		case countComprehension(x,y) => translateComprehension2("count",x,y)
		case sumComprehension(x,y) => translateComprehension2("sum",x,y)
		case vecComprehension(x,y) => translateComprehension2("vec",x,y)
		case setComprehension(x,y) => translateComprehension2("set",x,y)
		case equal(x,y) => application(variable("equal"),tup([x,y]))
		case lesseq(x,y) => application(variable("lessEq"),tup([x,y]))
		case less(x,y) => application(variable("less"),tup([x,y]))
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

//Expression translateAccu(str kind, Expression accu, Expression item) {
//	switch(kind) {
//	case "list":
//		abstraction(["accu",item], )
//	}
//}

public Expression translateComprehension2(str kind, Expression header, list[Expression] parts) {
	switch(kind) {
	case "list":
		return translateComprehensionRec(kind, variable("emptyList"), variable("addMut"), header, parts);
	case "set":
		return translateComprehensionRec(kind, variable("emptySet"), variable("addMut"), header, parts);		
	case "sum":
		return translateComprehensionRec(kind, const(0.0), variable("whocares"), header, parts);
	case "count":
		return translateComprehensionRec(kind, const(0.0), variable("whocares"), header, parts);		
	case "some":
		return translateComprehensionRec(kind, variable("false"), abstraction(["x","y"], or(variable("x"), variable("y"))), header, parts);
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
	case "sum":
		return application(variable("sum"), tup([x,y]));		
	}
}

public Expression translateComprehensionRec(str kind, Expression zero, Expression merge, Expression header, list[Expression] parts) {
	if (parts == []) {
		//return application(merge, tup([zero,header]));
		//switch(zero) {
		//	case variable(v):
		//		return mergeBody(kind, zero, header);
		//}
		return mergeBody(kind, zero, header);
		
	} else {
		first = head(parts);
		switch (first) {
			case generator(var,exp):
				return translateGenerator(kind, var, exp, zero, merge, header, parts);
			case setGenerator(var,exp):
				return translateSetGenerator(kind, var, exp, zero, merge, header, parts);				
			case matrixGenerator(row,col,exp):
				return translateMatrixGenerator(kind, row, col, exp, zero, merge, header, parts);
			case filt(exp): 
				return branch(exp, translateComprehensionRec(kind, zero, merge, header,tail(parts)), zero);
			case bind(var,exp): {
				alt = [generator(var,application(variable("singletonList"),tup([exp])))] + tail(parts);
				return translateComprehensionRec(kind, zero, merge, header,alt);
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

public Expression translateComprehension(str kind, Expression header, list[Expression] parts) {
	<zero,unit,merge> = comprehensionTriple(kind);
	//zero = abstraction(["yo"],zero); 
	if (parts == []) {
		return application(unit, tup([header]));
	} else {
		first = head(parts);
		switch (first) {
			case generator(var,exp):  
				return application(variable("reduceList"), 
					tup([zero,
						 variable("identity"),
						 //abstraction([var], translateComprehension(kind, header,tail(parts))),
						 abstraction(["accu",var], 
						             application(merge, tup([variable("accu"),
						                                     translateComprehension(kind, header,tail(parts))]))), 
					     exp]));
			//case generator(var,exp):  
			//	return application(variable("reduceList"), 
			//		tup([zero,
			//			 abstraction([var], translateComprehension(kind, header,tail(parts))),
			//			 merge, 
			//		     exp]));
			//case matrixGenerator(var,exp):  
			//	return application(variable("reduceMatrix"), 
			//		tup([zero,
			//			 abstraction([var], translateComprehension(kind, header,tail(parts))),
			//			 merge, 
			//		     exp]));
			case matrixGenerator(row,col,exp):  
				return application(application(variable("reduceMatrix"), 
					tup([zero,
						 abstraction([row,col], abstraction(["yo"], translateComprehension(kind, header,tail(parts)))),
						 merge, 
					     exp])), tup([const(1.0)]));
			case setGenerator(var,exp):  
				return application(application(variable("reduceSet"), 
					tup([zero,
						 abstraction([var], abstraction(["yo"], translateComprehension(kind, header,tail(parts)))),
						 merge, 
					     exp])), tup([const(1.0)]));
			case bind(var,exp): {
				alt = [generator(var,application(variable("singletonList"),tup([exp])))] + tail(parts);
				return translateComprehension(kind,header,alt);
			}
			case filt(exp): 
				return application(branch(exp, abstraction(["yo"], translateComprehension(kind,header,tail(parts))), zero),
								   tup([const(1.0)]));
		}
	}
}


Expression delay(Expression exp) {
	return abstraction([],exp);
}

Expression force(Expression exp) {
	return application(exp, tup([]));
}

tuple[Expression,Expression,Expression] comprehensionTriple(str kind) {
	dummy = tup([const(1.0)]);
	switch (kind) {
		case "list": return <variable("emptyList"),
							 variable("identity"),
							 variable("addMut")>;
		//case "list": return <variable("emptyList"),
		//					 variable("singletonList"),
		//					 abstraction(["ac","de"], application(variable("addMut"),tup([variable("ac"), application(variable("head"), tup([variable("de")]))])))>;
		//case "list": return <variable("emptyList"),
		//					 abstraction(["un"], delay(variable("un"))),
		//					 abstraction(["ac","de"], application(variable("addMut"),tup([variable("ac"), force(variable("de"))])))>;
		//case "list": return <variable("emptyList"),
		//					 variable("singletonList"),
		//					 abstraction(["x","y"],abstraction(["yo"],application(variable("append"),tup([application(variable("x"), dummy), application(variable("y"), dummy)]))))>;
		case "some": return <variable("false"),
							 variable("identity"),
							 abstraction(["x","y"], or(variable("x"), variable("y")))>;
		//case "some": return <variable("false"),
		//					 variable("identity"),
		//					 abstraction(["x","y"],abstraction(["yo"], or(application(variable("x"), dummy), application(variable("y"), dummy))))>;
		case "all": return <variable("true"),
							variable("identity"),
							abstraction(["x","y"],abstraction(["yo"], and(application(variable("x"), dummy), application(variable("y"), dummy))))>;
		//case "all": return <variable("true"),variable("identity"),abstraction(["x","y"],and(variable("x"),variable("y")))>;
		case "count": return <const(0.0),
							  abstraction(["x"],const(1.0)),
							  abstraction(["x","y"],abstraction(["yo"],application(variable("sum"),tup([application(variable("x"), dummy), application(variable("y"), dummy)]))))>;		
		case "sum": return <const(0.0),
							variable("identity"),
							abstraction(["x","y"],abstraction(["yo"],application(variable("sum"),tup([application(variable("x"), dummy), application(variable("y"), dummy)]))))>;
		case "vec": return <const(0.0),
							variable("identity"),
							abstraction(["x","y"],abstraction(["yo"],application(variable("sum"),tup([application(variable("x"), dummy), application(variable("y"), dummy)]))))>;
		case "set": return <variable("emptySet"),
							variable("singletonSet"),
							abstraction(["x","y"],abstraction(["yo"],application(variable("union"),tup([application(variable("x"), dummy), application(variable("y"), dummy)]))))>;
	}
}

tuple[Expression,Expression,Expression] comprehensionTripleOLD(str kind) {
	switch (kind) {
		case "list": return <variable("emptyList"),variable("singletonList"),variable("append")>;
		case "some": return <variable("false"),variable("identity"),abstraction(["x","y"],or(variable("x"),variable("y")))>;
		case "all": return <variable("true"),variable("identity"),abstraction(["x","y"],and(variable("x"),variable("y")))>;
		//case "all": return <variable("true"),variable("identity"),abstraction(["x","y"],and(variable("x"),variable("y")))>;
		case "count": return <const(0.0),abstraction(["x"],const(1.0)),variable("sum")>;		
		case "sum": return <const(0.0),variable("identity"),variable("sum")>;
		case "vec": return <const(0.0),variable("identity"),variable("sum")>;
		case "set": return <variable("emptySet"),variable("singletonSet"),variable("union")>;
	}
}

public str pprint(Expression exp) {
	switch(exp) {
		case variable(x): return "<x>";
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
 				
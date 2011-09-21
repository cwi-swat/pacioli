module lang::pacioli::compile::pacioli2mvm

import IO;
import List;

import lang::pacioli::ast::KernelPacioli;


int glbcounter = 0;

str fresh(str x) {glbcounter += 1; return "<x><glbcounter>";}


public str compilePacioli(Expression exp, str prelude) {
	code = compileExpression(exp);
	reg = fresh("r");
	prog = "<prelude>;
		   'eval <reg> <code>; 
	       'print <reg>";
	return prog;
}


public str compileExpression(Expression exp) {
	switch (exp) {
		case variable(x): {
			return x; 
		}
		case const(x): {
			return "<x>"; 
		}
		case branch(c,p,n): {
			return "if(<compileExpression(c)>,<compileExpression(p)>,<compileExpression(n)>)";
		}
		case and(x,y): {
			return "and(<compileExpression(x)>,<compileExpression(y)>)";
		}
		case or(x,y): {
			return "or(<compileExpression(x)>,<compileExpression(y)>)";
		}
		case abstraction(vars, body): {
			args = "";
			sep = "";
			for (x <- vars) {
				args += sep + x;
				sep = ", ";
			}
			return "lambda (<args>) <compileExpression(body)>";
		}
		case application(fn, tup(args)): {
			params = compileExpression(fn);
			for (x <- args) { 
				params += ", " + compileExpression(x);
			}
			return "apply(<params>)";
		}
		default: {
			throw("Cannot compile <exp> <pprint(exp)>");
		}
	}
}

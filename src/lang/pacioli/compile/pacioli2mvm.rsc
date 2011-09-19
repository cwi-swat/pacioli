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
			throw("Cannot compile <pprint(exp)>");
		}
	}
}

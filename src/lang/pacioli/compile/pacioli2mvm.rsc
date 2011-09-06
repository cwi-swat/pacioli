module lang::pacioli::compile::pacioli2mvm

import units::units;
import units::unification;
import lang::pacioli::ast::KernelPacioli;
import lang::pacioli::utils::Implode;
import lang::pacioli::types::Types;
import IO;

int glbcounter = 0;

str fresh(str x) {glbcounter += 1; return "<x><glbcounter>";}

alias Register = map[str var, str register];

public str compilePacioli(Expression exp, str prelude) {
	<code,reg> = compileExpression(exp,());
	prog = "<prelude>;
		   '<code>; 
	       'print <reg>";
	return prog;
}

public tuple[str,str] compileExpression(Expression exp, Register reg) {
	switch (exp) {
		case variable(x): {
			return <"skip", (x in reg) ? reg[x] : x>; 
		}
		case application(abstraction(var,body),arg): {
			<c1,r1> = compileExpression(arg,reg);
			<c2,r2> = compileExpression(body,reg+(var:r1));
			return <"<c1>;\n<c2>", r2>;
		}
		case application(variable(fn),pair2(a,b)): {
			<c1,r1> = compileExpression(a,reg);
			<c2,r2> = compileExpression(b,reg);
			r = fresh("r");
			return <"<c1>;\n<c2>;\n<fn> <r> <r1> <r2>", r>;
		}
		case application(variable(fn),arg): {
			<c1,r1> = compileExpression(arg,reg);
			r = fresh("r");
			return <"<c1>;\n<fn> <r> <r1>", r>;
		}
		default: throw("Functions and pairs as values not (yet) supported <exp>");
	}
}

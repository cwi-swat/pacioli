module lang::pacioli::compile::pacioli2mvm

import IO;
import List;

import units::units;
import units::unification;
import lang::pacioli::ast::KernelPacioli;
import lang::pacioli::utils::Implode;
import lang::pacioli::types::Types;


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

public map[&T,&U] zip(list[&T] x, list[&U] y) =
	(x == [] || y == []) ? () : (head(x):head(y)) + zip(tail(x),tail(y));


public tuple[str,str] compileExpression(Expression exp, Register reg) {
	switch (exp) {
		case variable(x): {
			return <"skip", (x in reg) ? reg[x] : x>; 
		}
		case application(fn, tup(args)): {
			registers = [];
			prog = "";
			sep = "";
			for (x <- args) {
				<c,r> = compileExpression(x,reg);
				registers += [r];
				prog += sep + c;
				sep = ";\n";
			}
			switch (fn) {
				case abstraction(vars,body): {
					<c,r> = compileExpression(body,reg+zip(vars,registers));
					return <prog+sep+c,r>;
				} 
				case variable(f): {
					r = fresh("r");
					return <"<prog><sep><f> <r><("" | it + " " + v | v <- registers)>", r>;
				}
			}
		}
		default: throw("Functions as values not (yet) supported <exp>");
	}
}

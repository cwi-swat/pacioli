module lang::pacioli::compile::pacioli2java

import units::units;
import units::unification;
import lang::pacioli::ast::KernelPacioli;
import lang::pacioli::utils::Implode;
import lang::pacioli::types::Types;

// Unused and unfinished experiment. Based on a Scheme to Java compiler 
// by Matt Might. See http://matt.might.net/articles/compiling-to-java.

public str compileToJava(Expression exp) {
	code = compileExpression(exp);
	prog = "// Generated Java code from Pacioli;
	
	interface PacioliValue {
		public String pprint();
	}
	
	class Closure  implements PacioliValue {
		public String pprint() {return \"|some closure|\";};
	}
	
		   'public class tmp {
		   '    public static void main(String[] args) {
		   '       final Closure join = new Closure();
		   '       System.out.println(<code>);
		   '    }
		   '}";
	return prog;
}

private str compileExpression(Expression exp) {
	
	switch (exp) {
		case variable(x): {
			return "<x>"; 
		}
		case abstraction(vars,body): {
			compiledVars = "";
			return "new Closure() {
				   '    public PacioliValue apply (<compiledVars>) {
				   '        return <compileExpression(body)>;
				   '    }
				   '}";
		}
		case application(fn, tup(args)): {
			compiledArgs = "";
			sep = "";
			for (x <- args) {
				compiled = compileExpression(x);
				compiledArgs += sep + compiled;
				sep = ", ";
			}
			return "<compileExpression(fn)>.apply(<compiledArgs>)";
		}
		default: return "System.out.println(\"Hello world!\");"; 
	}
}
package mvm.values;

import java.io.IOException;
import java.util.List;

import mvm.Environment;
import mvm.expressions.Expression;

public class Closure implements Callable {

	public final List<String> arguments;
	public final Expression code;
	public final Environment environment;
	
	public Closure(List<String> args, Expression expression, Environment env) {
		arguments = args;
		code = expression;
		environment = env;
	}
	
	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		Environment frame = new Environment(arguments, params); 
		return code.eval(frame.pushUnto(environment));
	}

	public String pprint() {
		return "|some closure|";
	}
}

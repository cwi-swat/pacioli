package mvm.values;

import java.io.IOException;
import java.util.List;

import mvm.Environment;
import mvm.expressions.Expression;

public class Closure implements Callable {

	private List<String> arguments;
	private Expression code;
	private Environment environment;
	
	public Closure(List<String> args, Expression expression, Environment env) {
		arguments = args;
		code = expression;
		environment = env;
	}
	
	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		//return code.eval(environment.extend(new Environment(arguments, params)));
		Environment frame = new Environment(arguments, params); 
		return code.eval(frame.pushUnto(environment));
	}

	public String pprint() {
		return "|some closure|";
	}

	// hack for recursive functions
	public Callable extend(Environment env) {
		//return new Closure(arguments,code,env.extend(environment));
		return new Closure(arguments,code,environment.pushUnto(env));
	}
}

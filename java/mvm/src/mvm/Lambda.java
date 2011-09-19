package mvm;

import java.util.List;

public class Lambda implements Expression {

	private List<String> arguments;
	private Expression expression;

	public Lambda(List<String> args, Expression body) {
		arguments = args;
		expression = body;
	}
	
	@Override
	public PacioliValue eval(Environment env) {
		return new Closure(arguments, expression, env);
	}

}

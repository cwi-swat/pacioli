package mvm;

import java.util.List;

public class Lambda implements Expression {

	private List<String> arguments;
	private Expression expression;

	public Lambda(List<String> args, Expression body) {
		arguments = args;
		expression = body;
	}
	
	public PacioliValue eval(Environment env) {
		return new Closure(arguments, expression, env);
	}

	public String pprint() {
		String args = "";
		String sep = "";
		for (String arg: arguments) {
			args += sep + arg;
			sep = ",";
		}
		return String.format("lambda (%s) %s", args, expression.pprint());
	}

}

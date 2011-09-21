package mvm.expressions;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import mvm.Environment;
import mvm.values.Callable;
import mvm.values.PacioliValue;

public class Application implements Expression {

	private Expression function;
	private List<Expression> arguments;

	public Application(Expression fun, List<Expression> args) {
		function = fun;
		arguments = args;
	}

	public PacioliValue eval(Environment env) throws IOException {
		PacioliValue fun = function.eval(env);
		if (fun instanceof Callable) {
			List<PacioliValue> params = new ArrayList<PacioliValue>();
			for (Expression exp: arguments) {
				params.add(exp.eval(env));
			}
			return ((Callable) fun).apply(params); 
		} else {
			throw new IOException("Function application argument is not a function");
		}
	}

	public String pprint() {
		String args = "";
		String sep = ",";
		for (Expression arg: arguments) {
			args += sep + arg.pprint();
		}
		return String.format("application(%s%s)", function.pprint(), args);
	}
}

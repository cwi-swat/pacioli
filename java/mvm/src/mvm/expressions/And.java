package mvm.expressions;

import java.io.IOException;

import mvm.Environment;
import mvm.values.Boole;
import mvm.values.PacioliValue;

public class And implements Expression {

	private final Expression lhs;
	private final Expression rhs;

	public And(Expression lhs, Expression rhs) {
		this.lhs = lhs;
		this.rhs = rhs;
	}

	public PacioliValue eval(Environment env) throws IOException {
		Boole outcome = (Boole) lhs.eval(env); 
		if (outcome.positive()) {
			return rhs.eval(env);
		} else {
			return outcome;
		}
	}

	public String pprint() {
		return String.format("and(%s,%s)", lhs.pprint(), rhs.pprint());
	}
}

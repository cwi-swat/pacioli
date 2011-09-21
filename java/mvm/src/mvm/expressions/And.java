package mvm.expressions;

import java.io.IOException;

import mvm.Boole;
import mvm.Environment;
import mvm.Expression;
import mvm.PacioliValue;

public class And implements Expression {

	private Expression lhs;
	private Expression rhs;

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

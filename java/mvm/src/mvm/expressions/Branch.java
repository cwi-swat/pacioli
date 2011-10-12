package mvm.expressions;

import java.io.IOException;

import mvm.Environment;
import mvm.values.Boole;
import mvm.values.PacioliValue;

public class Branch implements Expression {

	private final Expression test;
	private final Expression positive;
	private final Expression negative;

	public Branch(Expression test, Expression pos, Expression neg) {
		this.test = test;
		this.positive = pos;
		this.negative = neg;
	}
	
	public PacioliValue eval(Environment env) throws IOException {
		Boole outcome = (Boole) test.eval(env); 
		if (outcome.positive()) {
			return positive.eval(env);
		} else {
			return negative.eval(env);
		}
	}

	public String pprint() {
		return String.format("if(%s,%s,%s)", test.pprint(), positive.pprint(), negative.pprint());
	}

}

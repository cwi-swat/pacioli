package mvm.expressions;

import java.io.IOException;

import mvm.Environment;
import mvm.values.PacioliValue;

public class Variable implements Expression {

	private final String name;
	
	public Variable(String name) {
		this.name = name;
	}
	
	public String getName() {
		return name;
	};
	
	public PacioliValue eval(Environment env) throws IOException {
		return env.lookup(name);
	}

	public String pprint() {
		return name;
	}

}

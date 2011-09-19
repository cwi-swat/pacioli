package mvm;

import java.io.IOException;

public class Variable implements Expression {

	private String name;
	
	public Variable(String name) {
		this.name = name;
	}
	
	public String getName() {
		return name;
	};
	
	public PacioliValue eval(Environment env) throws IOException {
		return env.lookup(name);
	}

}

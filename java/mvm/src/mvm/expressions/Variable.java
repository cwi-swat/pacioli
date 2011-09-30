package mvm.expressions;

import java.io.IOException;

import mvm.Environment;
import mvm.values.Closure;
import mvm.values.PacioliValue;

public class Variable implements Expression {

	private String name;
	
	public Variable(String name) {
		this.name = name;
	}
	
	public String getName() {
		return name;
	};
	
	public PacioliValue eval(Environment env) throws IOException {

		PacioliValue value = env.lookup(name);
		
		// hack for recursive functions
//		if (value instanceof Closure) {
//			return ((Closure) value).extend(env);
//		}
				
		return value;
	}

	public String pprint() {
		return name;
	}

}

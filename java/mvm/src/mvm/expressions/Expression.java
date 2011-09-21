package mvm.expressions;

import java.io.IOException;

import mvm.Environment;
import mvm.values.PacioliValue;

public interface Expression {
	
	public PacioliValue eval(Environment env) throws IOException;
	public String pprint();
}

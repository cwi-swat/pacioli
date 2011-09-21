package mvm.expressions;

import java.io.IOException;

import mvm.Environment;
import mvm.PacioliValue;

public interface Expression {
	
	public PacioliValue eval(Environment env) throws IOException;
	public String pprint();
}

package mvm;

import java.io.IOException;

public interface Expression {
	
	public PacioliValue eval(Environment env) throws IOException;

}

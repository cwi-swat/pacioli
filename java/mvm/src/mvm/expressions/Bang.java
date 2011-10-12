package mvm.expressions;

import java.io.IOException;

import mvm.Environment;
import mvm.values.PacioliValue;
import mvm.values.matrix.Index;
import mvm.values.matrix.Matrix;
import units.PowerProduct;

public class Bang implements Expression {

	private final Index index;

	
	public Bang(Index index) {
		this.index = index;
	}

	public PacioliValue eval(Environment env) throws IOException {
		return new Matrix(new PowerProduct(), index, new Index()).ones();
	}

	public String pprint() {
		return "bang(" + "todo: bang pprint" + ")";
	}

}

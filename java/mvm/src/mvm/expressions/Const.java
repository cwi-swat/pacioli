package mvm.expressions;

import java.io.IOException;

import mvm.Environment;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;


public class Const implements Expression {

	private final Matrix matrix;

	public Const(Matrix matrix) {
		this.matrix = matrix;
	}

	public PacioliValue eval(Environment env) throws IOException {
		return matrix;
	}

	public String pprint() {
		return matrix.pprint();
	}

}

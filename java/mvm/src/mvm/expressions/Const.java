package mvm.expressions;

import java.io.IOException;

import mvm.Environment;
import mvm.Expression;
import mvm.Matrix;
import mvm.PacioliValue;


public class Const implements Expression {

	private Matrix matrix;

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

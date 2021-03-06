package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class Abs implements Callable {

	public String pprint() {
		return "|abs|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'abs' expects one argument");
		}
		if (!(params.get(0) instanceof Matrix)) {
			throw new IOException("argument to function 'abs' is not a matrix");
		}
		Matrix x = (Matrix) params.get(0);
		return x.abs();
	}
}

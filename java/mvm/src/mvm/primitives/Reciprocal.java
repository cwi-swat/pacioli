package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.Callable;
import mvm.Matrix;
import mvm.PacioliValue;

public class Reciprocal implements Callable {

	public String pprint() {
		return "reciprocal";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'reciprocal' expects one argument");
		}
		if (!(params.get(0) instanceof Matrix)) {
			throw new IOException("argument to function 'reciprocal' is not a matrix");
		}
		Matrix x = (Matrix) params.get(0);
		return x.reciprocal();
	}
}

package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.Callable;
import mvm.Matrix;
import mvm.PacioliValue;

public class Transpose implements Callable {

	public String pprint() {
		return "transpose";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'transpose' expects one argument");
		}
		if (!(params.get(0) instanceof Matrix)) {
			throw new IOException("argument to function 'transpose' is not a matrix");
		}
		Matrix x = (Matrix) params.get(0);
		return x.transpose();
	}
}

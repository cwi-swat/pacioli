package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class Kleene implements Callable {

	public String pprint() {
		return "|kleene|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'kleene' expects one argument");
		}
		if (!(params.get(0) instanceof Matrix)) {
			throw new IOException("argument to function 'kleene' is not a matrix");
		}
		Matrix x = (Matrix) params.get(0);
		return x.kleene();
	}

}

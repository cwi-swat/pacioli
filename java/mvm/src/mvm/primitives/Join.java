package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class Join implements Callable {

	public String pprint() {
		return "|join|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 2) {
			throw new IOException("function 'join' expects two arguments");
		}
		if (!(params.get(0) instanceof Matrix)) {
			throw new IOException("first argument to function 'join' is not a matrix");
		}
		if (!(params.get(1) instanceof Matrix)) {
			throw new IOException("second argument to function 'join' is not a matrix");
		}
		Matrix x = (Matrix) params.get(0);
		Matrix y = (Matrix) params.get(1);
		if (x.isZero()) {
			return x;
		}
		if (y.isZero()) {
			return y;
		}
		return x.join(y);
	}

}

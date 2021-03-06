package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class Total implements Callable {

	public String pprint() {
		return "|total|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'total' expects two arguments");
		}
		if (!(params.get(0) instanceof Matrix)) {
			throw new IOException("argument to function 'total' is not a matrix");
		}
		Matrix x = (Matrix) params.get(0);
//		if (x.isZero()) {
//			return x;
//		}
		return x.total(); 
	}

}

package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class SVD implements Callable {

	public String pprint() {
		return "|svd|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'svd' expects one argument");
		}
		if (!(params.get(0) instanceof Matrix)) {
			throw new IOException("argument to function 'svd' is not a matrix");
		}
		//Matrix x = (Matrix) params.get(0);
		//return x.svd();
		throw new IOException("Singular Value Decomposition not implemented.");
	}

}

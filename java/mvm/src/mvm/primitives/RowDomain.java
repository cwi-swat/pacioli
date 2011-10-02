package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class RowDomain implements Callable {

	public String pprint() {
		return "|rowDomain|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'rowDomain' expects one argument");
		}
		if (!(params.get(0) instanceof Matrix)) {
			throw new IOException("argument to function 'rowDomain' is not a matrix");
		}
		Matrix matrix = (Matrix) params.get(0);
		return matrix.rowDomain();
	}

}

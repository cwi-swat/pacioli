package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class UnitFactor implements Callable {

	public String pprint() {
		return "|unitFactor|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'unitFactor' expects one argument");
		}
		if (!(params.get(0) instanceof Matrix)) {
			throw new IOException("argument to function 'unitFactor' is not a matrix");
		}
		Matrix matrix = (Matrix) params.get(0);
		return new Matrix(matrix.type.getFactor());
	}

}

package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class RightIdentity implements Callable {

	public String pprint() {
		return "rightIdentity";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'rightIdentity' expects one argument");
		}
		if (!(params.get(0) instanceof Matrix)) {
			throw new IOException("argument to function 'rightIdentity' is not a matrix");
		}
		Matrix x = (Matrix) params.get(0);
		return x.rightIdentity();
	}

}

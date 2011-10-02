package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.Key;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class Row implements Callable {

	public String pprint() {
		return "|row|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 2) {
			throw new IOException("function 'row' expects two arguments");
		}
		if (!(params.get(0) instanceof Matrix)) {
			throw new IOException("first argument to function 'row' is not a matrix");
		}
		if (!(params.get(1) instanceof Key)) {
			throw new IOException("second argument to function 'row' is not a key");
		}
		Matrix matrix = (Matrix) params.get(0);
		Key key = (Key) params.get(1);
		return matrix.row(key);
	}

}

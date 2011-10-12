package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class ColumnIndex implements Callable {

	public String pprint() {
		return "|columnIndex|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'columnIndex' expects one argument");
		}
		if (!(params.get(0) instanceof Matrix)) {
			throw new IOException("argument to function 'columnIndex' is not a matrix");
		}
		Matrix matrix = (Matrix) params.get(0);
		return matrix.columnIndex();
	}

}

package mvm.primitives;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliList;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class Columns implements Callable {

	public String pprint() {
		return "|columns|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'columns' expects one argument");
		}
		if (!(params.get(0) instanceof Matrix)) {
			throw new IOException("argument to function 'columns' is not a matrix");
		}
		Matrix matrix = (Matrix) params.get(0);
		List<PacioliValue> columns = new ArrayList<PacioliValue>();
		for (Matrix mat: matrix.columns()) {
			columns.add(mat);
		}
		return new PacioliList(columns);	
	}

}

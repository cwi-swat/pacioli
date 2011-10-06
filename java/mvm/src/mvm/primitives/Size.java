package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliList;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class Size implements Callable {

	public String pprint() {
		return "|size|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'size' expects one argument");
		}
		if (!(params.get(0) instanceof PacioliList)) {
			throw new IOException("first argument to function 'size' is not a list");
		}
		PacioliList x = (PacioliList) params.get(0);
		return new Matrix(x.items().size());
	}
}

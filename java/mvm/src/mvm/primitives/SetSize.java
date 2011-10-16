package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliSet;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class SetSize implements Callable {

	public String pprint() {
		return "|setSize|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'setSize' expects one argument");
		}
		if (!(params.get(0) instanceof PacioliSet)) {
			throw new IOException("first argument to function 'setSize' is not a set");
		}
		PacioliSet x = (PacioliSet) params.get(0);
		return new Matrix(x.items().size());
	}
}

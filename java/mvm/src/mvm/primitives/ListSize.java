package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliList;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class ListSize implements Callable {

	public String pprint() {
		return "|listSize|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'listSize' expects one argument");
		}
		if (!(params.get(0) instanceof PacioliList)) {
			throw new IOException("first argument to function 'listSize' is not a list");
		}
		PacioliList x = (PacioliList) params.get(0);
		return new Matrix(x.items().size());
	}
}

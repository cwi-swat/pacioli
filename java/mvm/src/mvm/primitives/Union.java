package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliSet;
import mvm.values.PacioliValue;

public class Union implements Callable {

	public String pprint() {
		return "|union|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 2) {
			throw new IOException("function 'union' expects two arguments");
		}
		if (!(params.get(0) instanceof PacioliSet)) {
			throw new IOException("first argument to function 'union' is not a set");
		}
		if (!(params.get(1) instanceof PacioliSet)) {
			throw new IOException("second argument to function 'union' is not a set");
		}
		PacioliSet x = (PacioliSet) params.get(0);
		PacioliSet y = (PacioliSet) params.get(1);
		return x.union(y);
	}

}

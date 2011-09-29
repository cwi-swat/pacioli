package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliSet;
import mvm.values.PacioliValue;

public class AdjoinMut implements Callable {

	public String pprint() {
		return "|adjoinMut|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 2) {
			throw new IOException("function 'adjoinMut' expects two arguments");
		}
		if (!(params.get(0) instanceof PacioliSet)) {
			throw new IOException("first argument to function 'adjoinMut' is not a set");
		}
		PacioliSet x = (PacioliSet) params.get(0);
		PacioliValue y =  params.get(1);
		return x.adjoinMut(y);
	}

}

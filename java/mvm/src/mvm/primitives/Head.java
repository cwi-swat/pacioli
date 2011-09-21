package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliList;
import mvm.values.PacioliValue;

public class Head implements Callable {

	public String pprint() {
		return "head";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'head' expects one argument");
		}
		if (!(params.get(0) instanceof PacioliList)) {
			throw new IOException("argument to function 'head' is not a list");
		}
		PacioliList x = (PacioliList) params.get(0);
		if (x.items().size() == 0) {
			throw new IOException("function 'head' called on empty list");
		}
		return x.items().get(0);
	}

}

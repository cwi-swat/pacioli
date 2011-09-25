package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliList;
import mvm.values.PacioliValue;

public class Zip implements Callable {

	public String pprint() {
		return "zip";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 2) {
			throw new IOException("function 'zip' expects two arguments");
		}
		if (!(params.get(0) instanceof PacioliList)) {
			throw new IOException("first argument to function 'zip' is not a list");
		}
		if (!(params.get(1) instanceof PacioliList)) {
			throw new IOException("second argument to function 'zip' is not a list");
		}
		PacioliList x = (PacioliList) params.get(0);
		PacioliList y = (PacioliList) params.get(1);
		return x.zip(y);
	}

}

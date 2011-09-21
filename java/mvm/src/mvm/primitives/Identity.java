package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliValue;

public class Identity implements Callable {

	public String pprint() {
		return "identity";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'identity' expects one argument");
		}
		return params.get(0);
	}

}

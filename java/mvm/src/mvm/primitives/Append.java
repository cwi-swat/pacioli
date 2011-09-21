package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.Callable;
import mvm.PacioliList;
import mvm.PacioliValue;

public class Append implements Callable {

	public String pprint() {
		return "append";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 2) {
			throw new IOException("function 'append' expects two arguments");
		}
		if (!(params.get(0) instanceof PacioliList)) {
			throw new IOException("first argument to function 'append' is not a list");
		}
		if (!(params.get(1) instanceof PacioliList)) {
			throw new IOException("second argument to function 'append' is not a list");
		}
		PacioliList x = (PacioliList) params.get(0);
		PacioliList y = (PacioliList) params.get(1);
		return x.append(y);
	}

}

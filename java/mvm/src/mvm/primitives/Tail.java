package mvm.primitives;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import mvm.Callable;
import mvm.PacioliList;
import mvm.PacioliValue;

public class Tail implements Callable {

	public String pprint() {
		return "tail";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'tail' expects one argument");
		}
		if (!(params.get(0) instanceof PacioliList)) {
			throw new IOException("argument to function 'tail' is not a list");
		}
		PacioliList x = (PacioliList) params.get(0);
		if (x.items().size() == 0) {
			throw new IOException("function 'tail' called on empty list");
		}
		List<PacioliValue> items = new ArrayList<PacioliValue>();
		for (int i=1; i<x.items().size();i++) {
			items.add(x.items().get(i));
		}
		return new PacioliList(items);
	}

}

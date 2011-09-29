package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliList;
import mvm.values.PacioliValue;

public class AddMut implements Callable {

	public String pprint() {
		return "|addMut|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 2) {
			throw new IOException("function 'addMut' expects two arguments");
		}
		if (!(params.get(0) instanceof PacioliList)) {
			throw new IOException("first argument to function 'addMut' is not a list");
		}
		PacioliList x = (PacioliList) params.get(0);
		PacioliValue y =  params.get(1);
		return x.addMut(y);
	}

}

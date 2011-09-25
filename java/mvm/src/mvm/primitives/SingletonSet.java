package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliSet;
import mvm.values.PacioliValue;

public class SingletonSet implements Callable {

	public String pprint() {
		return "singletonSet";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'singletonSet' expects two arguments");
		}
		return new PacioliSet(params.get(0));
	}

}

package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliTuple;
import mvm.values.PacioliValue;

public class Apply implements Callable {

	public String pprint() {
		return "|apply|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 2) {
			throw new IOException("function 'apply' expects two arguments");
		}
		if (!(params.get(0) instanceof Callable)) {
			throw new IOException("first argument to function 'apply' is not a function");
		}
		if (!(params.get(1) instanceof PacioliTuple)) {
			throw new IOException("second argument to function 'apply' is not a tuple");
		}
		Callable function = (Callable) params.get(0);
		PacioliTuple tuple = (PacioliTuple) params.get(1);
		return function.apply(tuple.items());
	}

}

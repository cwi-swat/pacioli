package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.Boole;
import mvm.Callable;
import mvm.PacioliValue;

public class Not implements Callable {

	public String pprint() {
		return "not";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'not' expects one argument");
		}
		if (!(params.get(0) instanceof Boole)) {
			throw new IOException("argument to function 'head' is not a Boolean");
		}
		Boole x = (Boole) params.get(0);
		return new Boole(!x.positive());
	}

}

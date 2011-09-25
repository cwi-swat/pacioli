package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliTuple;
import mvm.values.PacioliValue;

public class Tuple implements Callable {

	public String pprint() {
		return "|tuple|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		return new PacioliTuple(params);
	}

}

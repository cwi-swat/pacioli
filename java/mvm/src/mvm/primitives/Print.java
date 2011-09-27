package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliValue;

public class Print implements Callable {

	public String pprint() {
		return "|print|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'print' expects one argument");
		}
		PacioliValue value = params.get(0);
		System.out.println(value.pprint());
		return value;
	}

}

package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.Key;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class Set implements Callable {

	public String pprint() {
		return "|set|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 3) {
			throw new IOException("function 'set' expects three arguments");
		}
		if (!(params.get(0) instanceof Key)) {
			throw new IOException("first argument to function 'set' is not a key");
		}
		if (!(params.get(1) instanceof Key)) {
			throw new IOException("second argument to function 'set' is not a key");
		}
		if (!(params.get(2) instanceof Matrix)) {
			throw new IOException("third argument to function 'set' is not a matrix");
		}
		Key row = (Key) params.get(0);
		Key column = (Key) params.get(1);
		Matrix x = (Matrix) params.get(2);
		return x.set(row,column,x);
	}

}

package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.Key;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class Put implements Callable {

	public String pprint() {
		return "|put|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 4) {
			throw new IOException("function 'put' expects three arguments");
		}
		if (!(params.get(0) instanceof Matrix)) {
			throw new IOException("first argument to function 'put' is not a matrix");
		}
		if (!(params.get(1) instanceof Key)) {
			throw new IOException("second argument to function 'put' is not a key");
		}
		if (!(params.get(2) instanceof Key)) {
			throw new IOException("third argument to function 'put' is not a key");
		}
		if (!(params.get(3) instanceof Matrix)) {
			throw new IOException("fourth argument to function 'put' is not a singleton");
		}
		Matrix x = (Matrix) params.get(0);
		Key row = (Key) params.get(1);
		Key column = (Key) params.get(2);
		Matrix value = (Matrix) params.get(3);
		return x.put(row,column,value);
	}
}

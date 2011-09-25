package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.Key;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class Isolate implements Callable {

	public String pprint() {
		return "isolate";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 3) {
			throw new IOException("function 'isolate' expects three arguments");
		}
		if (!(params.get(0) instanceof Matrix)) {
			throw new IOException("first argument to function 'isolate' is not a matrix");
		}
		if (!(params.get(1) instanceof Key)) {
			throw new IOException("second argument to function 'isolate' is not a key");
		}
		if (!(params.get(2) instanceof Key)) {
			throw new IOException("third argument to function 'isolate' is not a key");
		}
		Matrix x = (Matrix) params.get(0);
		Key row = (Key) params.get(1);
		Key column = (Key) params.get(2);
		return x.isolate(row,column);
	}

}

package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Boole;
import mvm.values.Callable;
import mvm.values.Key;
import mvm.values.PacioliValue;

public class IndexLess implements Callable {

	public String pprint() {
		return "|indexLess|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 2) {
			throw new IOException("function 'indexLess' expects two arguments");
		}
		if (!(params.get(0) instanceof Key)) {
			throw new IOException("first argument to function 'indexLess' is not a key");
		}
		if (!(params.get(1) instanceof Key)) {
			throw new IOException("second argument to function 'indexLess' is not a key");
		}
		Key row = (Key) params.get(0);
		Key column = (Key) params.get(1);
		return new Boole(row.index.ElementPos(row.names) < column.index.ElementPos(column.names));

	}

}

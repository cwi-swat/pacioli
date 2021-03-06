package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Boole;
import mvm.values.Callable;
import mvm.values.PacioliValue;

public class Equal implements Callable {
	
	public String pprint() {
		return "|equal|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 2) {
			throw new IOException("function 'equal' expects two arguments");
		}
//		if (!(params.get(0) instanceof Matrix)) {
//			throw new IOException("first argument to function 'equal' is not a matrix");
//		}
//		if (!(params.get(1) instanceof Matrix)) {
//			throw new IOException("second argument to function 'equal' is not a matrix");
//		}
		
//		Matrix x = (Matrix) params.get(0);
//		Matrix y = (Matrix) params.get(1);
//		if (x.isZero() && y.isZero()) {
//			return new Boole(true);
//		} else {
//			return new Boole(x.equals(y));
//		}
		return new Boole(params.get(0).equals(params.get(1)));
	}

}


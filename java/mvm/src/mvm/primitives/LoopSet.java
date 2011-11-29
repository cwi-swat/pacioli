package mvm.primitives;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliSet;
import mvm.values.PacioliValue;

public class LoopSet implements Callable {

	public String pprint() {
		return "|loopSet|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 3) {
			throw new IOException("function 'loopSet' expects three arguments");
		}
		if (!(params.get(1) instanceof Callable)) {
			throw new IOException("second argument to function 'loopSet' is not a function");
		}
		if (!(params.get(2) instanceof PacioliSet)) {
			throw new IOException("third argument to function 'loopSet' is not a set");
		}
		PacioliValue zero = params.get(0);
		Callable merge = (Callable) params.get(1);
		List<PacioliValue> set = ((PacioliSet) params.get(2)).items();
		PacioliValue accu = zero;
		for (PacioliValue value: set) {
			accu = applyToTwo(merge, accu, value);
		}
		return accu;
	}

	private PacioliValue applyToTwo(Callable fun, PacioliValue arg0, PacioliValue arg1) throws IOException {
		List<PacioliValue> temp = new ArrayList<PacioliValue>();
		temp.add(arg0);
		temp.add(arg1);
		return fun.apply(temp);
	}
	
}

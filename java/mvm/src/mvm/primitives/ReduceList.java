package mvm.primitives;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliList;
import mvm.values.PacioliValue;

public class ReduceList implements Callable {

	public String pprint() {
		return "|reduceList|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 4) {
			throw new IOException("function 'reduceList' expects four arguments");
		}
		if (!(params.get(1) instanceof Callable)) {
			throw new IOException("second argument to function 'reduceList' is not a function");
		}
		if (!(params.get(2) instanceof Callable)) {
			throw new IOException("third argument to function 'reduceList' is not a function");
		}
		if (!(params.get(3) instanceof PacioliList)) {
			throw new IOException("fourth argument to function 'reduceList' is not a list");
		}
		PacioliValue zero = params.get(0);
		Callable fun = (Callable) params.get(1);
		Callable merge = (Callable) params.get(2);
		List<PacioliValue> list = ((PacioliList) params.get(3)).items();
		PacioliValue accu = zero;
		for (PacioliValue value: list) {
			accu = applyToTwo(merge, accu, applyToOne(fun,value));
		}
		return accu;
	}

	private PacioliValue applyToTwo(Callable fun, PacioliValue arg0, PacioliValue arg1) throws IOException {
		List<PacioliValue> temp = new ArrayList<PacioliValue>();
		temp.add(arg0);
		temp.add(arg1);
		return fun.apply(temp);
	}

	private PacioliValue applyToOne(Callable fun, PacioliValue arg) throws IOException {
		List<PacioliValue> temp = new ArrayList<PacioliValue>();
		temp.add(arg);
		return fun.apply(temp);
	}
	
}

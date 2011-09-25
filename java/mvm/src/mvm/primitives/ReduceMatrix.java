package mvm.primitives;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import mvm.values.Callable;
import mvm.values.Key;
import mvm.values.PacioliValue;
import mvm.values.matrix.Matrix;

public class ReduceMatrix implements Callable {

	public String pprint() {
		return "reduceMatrix";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 4) {
			throw new IOException("function 'reduceMatrix' expects four arguments");
		}
		if (!(params.get(1) instanceof Callable)) {
			throw new IOException("second argument to function 'reduceMatrix' is not a function");
		}
		if (!(params.get(2) instanceof Callable)) {
			throw new IOException("third argument to function 'reduceMatrix' is not a function");
		}
		if (!(params.get(3) instanceof Matrix)) {
			throw new IOException("fourth argument to function 'reduceMatrix' is not a matrix");
		}
		PacioliValue zero = params.get(0);
		Callable fun = (Callable) params.get(1);
		Callable merge = (Callable) params.get(2);
		Matrix matrix = (Matrix) params.get(3);
		PacioliValue accu = zero;
//		for (PacioliValue value: matrix.elements()) {
//			accu = applyToTwo(merge, accu, applyToOne(fun,value));
//		}
		for (Key rowKey: matrix.rowKeys()) {
			for (Key columnKey: matrix.columnKeys()) {
				accu = applyToTwo(merge, accu, applyToTwo(fun, rowKey, columnKey));
			}
		}
		return accu;
	}

	private PacioliValue applyToTwo(Callable fun, PacioliValue arg0, PacioliValue arg1) throws IOException {
		List<PacioliValue> temp = new ArrayList<PacioliValue>();
		temp.add(arg0);
		temp.add(arg1);
		return fun.apply(temp);
	}

//	private PacioliValue applyToOne(Callable fun, PacioliValue arg) throws IOException {
//		List<PacioliValue> temp = new ArrayList<PacioliValue>();
//		temp.add(arg);
//		return fun.apply(temp);
//	}
}

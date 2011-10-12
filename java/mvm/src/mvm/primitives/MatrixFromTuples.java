package mvm.primitives;

import java.io.IOException;
import java.util.List;

import mvm.values.Callable;
import mvm.values.Key;
import mvm.values.PacioliSet;
import mvm.values.PacioliTuple;
import mvm.values.PacioliValue;
import mvm.values.matrix.Index;
import mvm.values.matrix.Matrix;

public class MatrixFromTuples implements Callable {

	public String pprint() {
		return "|matrix|";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'matrix' expects one argument");
		}
		if (!(params.get(0) instanceof PacioliSet)) {
			throw new IOException("argument to function 'matrix' is not a set");
		}
		List<PacioliValue> list = ((PacioliSet) params.get(0)).items();
		if (list.size() == 0) {
			return new Matrix(0);
		} else {
			
			PacioliValue first = list.get(0);
			
			if (!(first instanceof PacioliTuple)) {
				throw new IOException("argument to function 'matrix' is not a list of tuples");
			}
			
			List<PacioliValue> tupleItems = ((PacioliTuple) first).items();
			
			if (tupleItems.size() != 3) {
				throw new IOException("argument to function 'matrix' is not a list of tuples of three items");
			}
			
			if (!(tupleItems.get(0) instanceof Key && 
				  tupleItems.get(1) instanceof Key &&
				  tupleItems.get(2) instanceof Matrix)) {
				throw new IOException("argument to function 'matrix' is not a list of (key, key, matrix) tuples");
			}
			
			Key rowKey = (Key) tupleItems.get(0);
			Key columnKey = (Key) tupleItems.get(1);
			Matrix value = (Matrix) tupleItems.get(2);
			
			if (!(first instanceof PacioliTuple)) {
				throw new IOException("argument to function 'matrix' is not a list of tuples");
			}
			
			Index rowIndex = rowKey.index.homogeneousIndex();
			Index columnIndex = columnKey.index.homogeneousIndex();

			Matrix matrix = new Matrix(value.type.getFactor(), rowIndex, columnIndex);

			for (PacioliValue tuple: list) {
				
				tupleItems = ((PacioliTuple) tuple).items();
				
				rowKey = (Key) tupleItems.get(0);
				columnKey = (Key) tupleItems.get(1);
				value = (Matrix) tupleItems.get(2);

				matrix.setMut(rowKey, columnKey, value);
			}
			
			return matrix;
		}
	}
}

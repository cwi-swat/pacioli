package mvm.values.matrix;

import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import mvm.Tokenizer;
import mvm.values.Key;
import mvm.values.PacioliValue;

import org.ejml.simple.SimpleMatrix;

import units.PowerProduct;
import units.Unit;


public class Matrix implements PacioliValue {

	private MatrixType type;
	private Index rowIndex;
	private Index columnIndex;
	private SimpleMatrix numbers;
	
	public Matrix(MatrixType type, Index rowIndex, Index columnIndex){
		this.type = type;
		this.rowIndex = rowIndex;
		this.columnIndex = columnIndex;
		numbers = new SimpleMatrix(rowIndex.size(),columnIndex.size());
	}

	public Matrix transpose() {
		Matrix matrix = new Matrix(type.transpose(), columnIndex.reciprocal(), rowIndex.reciprocal());
		matrix.numbers = numbers.transpose();
		return matrix;
	}

	public Matrix sum(Matrix other) throws IOException {
		if (other.isZero()) {
			return this;
		} else if (this.isZero()) {
			return other;
		} else if (type.equals(other.type)) {
			Matrix matrix = new Matrix(type, rowIndex, columnIndex);
			matrix.numbers = numbers.plus(other.numbers);
			return matrix;
		} else {
			throw new IOException("types '" + type.pprint() + "' and '" + other.type.pprint() + "' not equal in sum");
		}
	}

	public Matrix multiply(Matrix other) throws IOException{
		if (type.multiplyable(other.type)) {
			Matrix matrix = new Matrix(type.multiply(other.type), rowIndex.multiply(other.rowIndex), columnIndex.multiply(other.columnIndex));
			matrix.numbers = numbers.elementMult(other.numbers);
			return matrix;
		} else {
			throw new IOException("types '" + type.pprint() + "' and '" + other.type.pprint() + "' not compatible for multiplication");
		}
	}
	
	public Matrix negative() {
		Matrix matrix = new Matrix(type, rowIndex, columnIndex);
		matrix.numbers = numbers.negative();
		return matrix;
	}

	public boolean isZero() {
		for (int i=0; i<numbers.numRows(); i++) {
			for (int j=0; j<numbers.numCols(); j++) {
				Double entry = numbers.get(i, j);
				if (entry != 0) {
					return false;	
				}	
			}
		}
		return true;
	}
	
	public Matrix reciprocal() {
		Matrix matrix = new Matrix(type.reciprocal(), rowIndex.reciprocal(), columnIndex.reciprocal());
		for (int i=0; i<numbers.numRows(); i++) {
			for (int j=0; j<numbers.numCols(); j++) {
				Double numerator = numbers.get(i, j);
				if (numerator != 0) {
					matrix.putDouble(i,j,1/numerator);	
				}	
			}
		}
		return matrix;
	}
	
	public Matrix join(Matrix other) throws IOException{
		if (type.joinable(other.type)) {
			Matrix matrix = new Matrix(type.join(other.type), rowIndex, other.columnIndex);
			matrix.numbers = numbers.mult(other.numbers);
			return matrix;
		} else {
			throw new IOException("types '" + type.pprint() + "' and '" + other.type.pprint() + "' not compatible for joining");
		}
	}

	public Matrix closure() throws IOException {
		if (type.unitSquare()) {
			Matrix matrix = new Matrix(type, rowIndex, columnIndex);
			SimpleMatrix ident = SimpleMatrix.identity(rowIndex.size());
			matrix.numbers = ident.minus(numbers).invert().minus(ident);
			return matrix; 
		} else {
			throw new IOException("type '" + type.pprint() + "' not square when taking closure");
		}
	}

	public Matrix kleene() throws IOException {
		if (type.unitSquare()) {
			Matrix matrix = new Matrix(type, rowIndex, columnIndex);
			SimpleMatrix ident = SimpleMatrix.identity(rowIndex.size());
			matrix.numbers = ident.minus(numbers).invert();
			return matrix; 
		} else {
			throw new IOException("type '" + type.pprint() + "' not square when taking kleene closure");
		}
	}

	public PacioliValue scale(Matrix other) throws IOException {
		if (type.singleton()) {
			Matrix matrix = new Matrix(type.scale(other.type), other.rowIndex, other.columnIndex);
			matrix.numbers = other.numbers.scale(numbers.get(0,0));
			return matrix;
		} else {
			throw new IOException("types '" + type.pprint() + "' and '" + other.type.pprint() + "' not compatible for scaling");
		}
	}

	public PacioliValue leftIdentity() {
		MatrixType identityType = type.leftIdentity();
		Matrix matrix = new Matrix(identityType, rowIndex, rowIndex);
		for (int i=0; i < numbers.numRows(); i++) {
			matrix.numbers.set(i, i, 1.0);
		}
		return matrix;
	}
	
	public PacioliValue rightIdentity() {
		MatrixType identityType = type.rightIdentity();
		Matrix matrix = new Matrix(identityType, columnIndex, columnIndex);
		for (int i=0; i < numbers.numCols(); i++) {
			matrix.numbers.set(i, i, 1.0);
		}
		return matrix;
	}
	
	public Matrix total() throws IOException {
		IndexType empty = new IndexType();
		Index index = new Index(empty ,null,null);
		MatrixType totalType = new MatrixType(type.getFactor(),empty,empty);
		Matrix matrix = new Matrix(totalType, index, index);
		matrix.numbers.set(0, 0, numbers.elementSum());
		return matrix; 
	}

	
	public List<Matrix> columns() throws IOException {
		List<Matrix> columns = new ArrayList<Matrix>();
		MatrixType extractedType = type.extractColumn();
		Index index = new Index(new IndexType(),null,null);
		for (int i=0; i < numbers.numCols(); i++) {
			Matrix matrix = new Matrix(extractedType, rowIndex, index);
			matrix.numbers = numbers.extractVector(false, i);
			columns.add(matrix);
		}
		return columns;
	}


	public List<Matrix> rows() throws IOException {
		List<Matrix> rows = new ArrayList<Matrix>();
		MatrixType extractedType = type.extractRow();
		Index index = new Index(new IndexType(),null,null);
		for (int i=0; i < numbers.numRows(); i++) {
			Matrix matrix = new Matrix(extractedType, index, columnIndex);
			matrix.numbers = numbers.extractVector(true, i);
			rows.add(matrix);
		}
		return rows;
	}
	
	private Unit unitAt(int i, int j) {
		return type.getFactor().multiply(rowIndex.unitAt(i).multiply(columnIndex.unitAt(j).raise(-1)));		
	}
	
	public String pprint() {
		Unit uno = new PowerProduct();
		if (type.rowOrder() == 0 && type.columnOrder() == 0) {
			if (unitAt(0,0).equals(uno)) {
				return String.format("%f", numbers.get(0,0));
			} else {
				return String.format("%f %s", numbers.get(0,0), unitAt(0,0).pprint());
			}				
		} else {
				
			//String output = "----------------------------------------------------------------------------------";
			String output = "";
			output += String.format("\n %50s %20s", "index", "value");
			output += "\n----------------------------------------------------------------------------------";
			Number num;
			Unit unit;
			for (int i=0; i<rowIndex.size(); i++){
				for (int j=0; j<columnIndex.size(); j++){
					num = numbers.get(i,j);
					if (num.doubleValue() != 0) {
						List<String> idx = new ArrayList<String>();
						idx.addAll(rowIndex.ElementAt(i));
						idx.addAll(columnIndex.ElementAt(j));
						unit = unitAt(i,j);
						if (unit.equals(uno)) {
							output += String.format("\n %50s %20f", idx, num);
						} else {
							output += String.format("\n %50s %20f %s", idx, num, unit);
						}
	//					output += String.format("\n %40s %40s %20f %s",
	//							rowIndex.ElementAt(i), columnIndex.ElementAt(j), num, unitAt(i,j).pprint());
					}
				}
			}
			return output;
		}
	}

	public String typeString() {
		return type.pprint();
	}
	
	public void load(String source) throws IOException {
		
		int rowWidth = rowIndex.width();
		int columnWidth = columnIndex.width();
		
		Tokenizer tokenizer = new Tokenizer(new FileReader(source), null);
		while (tokenizer.nextToken() != Tokenizer.TT_EOF) {
			tokenizer.pushBack();
			List<String> row = new ArrayList<String>();
			List<String> column = new ArrayList<String>();
			String name;
			for (int i=0; i<rowWidth; i++) {
				name = tokenizer.readString();
				row.add(name);
			}
			for (int i=0; i<columnWidth; i++) {
				name = tokenizer.readString();
				column.add(name);
			}
			double num = tokenizer.readNumber().doubleValue();
			numbers.set(rowIndex.ElementPos(row), columnIndex.ElementPos(column), num);
			tokenizer.readSeparator();
		}
		tokenizer.pushBack();
		
	}
	
	public void loadProjection() throws IOException {

		int nrRows = rowIndex.size();
		int nrColumns = columnIndex.size();
				
		List<String> dst;
		Unit srcUnit;
		Unit dstUnit; 
		Unit unit;
		
		for (int i=0; i<nrRows; i++) {
			
			List<String> src = rowIndex.ElementAt(i);
			
			for (int j=0; j<nrColumns; j++) {
				dst = columnIndex.ElementAt(j);
				
				if (src.containsAll(dst) || dst.containsAll(src)) {

					srcUnit = rowIndex.unitAt(i);
					dstUnit = columnIndex.unitAt(j);
					unit = (dstUnit.multiply(srcUnit.raise(-1))).flat();
					
					if (unit.bases().size() != 0) {
						throw new IOException(String.format("Cannot project '%s' to '%s'", 
								srcUnit.pprint(), dstUnit.pprint()));
					}

					numbers.set(i, j, 1.0);
				}
			}
		}
	}
	
	public void loadConversion() throws IOException {
		
		int nrRows = rowIndex.size();
		int nrColumns = columnIndex.size();
		
		if (nrRows != nrColumns) {
			throw new IOException("Conversion not square");
		}
		
		for (int i=0; i<nrRows; i++) {
			Unit src = rowIndex.unitAt(i);
			Unit dst = columnIndex.unitAt(i);
			Unit unit = (dst.multiply(src.raise(-1))).flat();
			if (unit.bases().size() != 0) {
				throw new IOException(String.format("Cannot convert '%s' to '%s'",
						src.pprint(), dst.pprint()));
			} else {
				Double num = unit.factor().doubleValue();
				numbers.set(i,i, num);
			}
		}
	}
	
	public int hashCode() {
		// It seems that the hashCode for numbers is not correct.
		// Pacioli expression equal(singletonSet(1),singletonSet(1)) 
		// gives false is the number's hashCode is used!
		//return numbers.hashCode();
		return type.hashCode();
	}
	
	public boolean equals(Object other) {
		if (other == this) {
			return true;
		}
		if (! (other instanceof Matrix)) {
			return false;
		}
		Matrix otherMatrix = (Matrix) other;
		if (this.isZero() && otherMatrix.isZero()) {
			return true;
		} else {
			return this.numbers.isIdentical(otherMatrix.numbers, 0.0);
		}
	}
	
//	public List<PacioliValue> elements() {
//		List<PacioliValue> elements = new ArrayList<PacioliValue>();
//		for (int i=0; i<numbers.numRows(); i++) {
//			for (int j=0; j<numbers.numCols(); j++) {
//				Double num = numbers.get(i, j);
//				if (num!= 0) {
//					Matrix matrix = new Matrix(type, rowIndex, columnIndex);
//					matrix.put(i, j, num);
//					elements.add(matrix);
//				}	
//			}
//		}
//		return elements;
//	}

	public List<Key> rowKeys() {
		List<Key> keys = new ArrayList<Key>();
		for (int i=0; i<rowIndex.size(); i++) {
			keys.add(new Key(rowIndex.ElementAt(i), rowIndex));
		}
		return keys;
	}
	
	public List<Key> columnKeys() {
		List<Key> keys = new ArrayList<Key>();
		for (int i=0; i<columnIndex.size(); i++) {
			keys.add(new Key(columnIndex.ElementAt(i), columnIndex));
		}
		return keys;
	}

	public PacioliValue get(Key row, Key column) throws IOException {
		IndexType empty = new IndexType();
		Index index = new Index(empty ,null,null);
		MatrixType entryType = new MatrixType(type.getFactor(),empty,empty);
		Matrix matrix = new Matrix(entryType, index, index);
		matrix.numbers.set(0, 0, numbers.get(rowIndex.ElementPos(row.names), columnIndex.ElementPos(column.names)));
		return matrix;
	}

	public PacioliValue magnitude(Key row, Key column) throws IOException {
		IndexType empty = new IndexType();
		Index index = new Index(empty ,null,null);
		MatrixType entryType = new MatrixType(new PowerProduct(),empty,empty);
		Matrix matrix = new Matrix(entryType, index, index);
		matrix.numbers.set(0, 0, numbers.get(rowIndex.ElementPos(row.names), columnIndex.ElementPos(column.names)));
		return matrix;
	}

	public Matrix putDouble(int i, int j, Double value) {
		numbers.set(i, j, value);
		return this;
	}

	public PacioliValue put(Key row, Key column, Matrix value) throws IOException {
		Matrix matrix = new Matrix(type, rowIndex, columnIndex);
		matrix.numbers = numbers.copy();
		matrix.putDouble(row.index.ElementPos(row.names), column.index.ElementPos(column.names), value.numbers.get(0,0));
		return matrix;
	}
	

	public PacioliValue set(Key row, Key column, Matrix x) throws IOException {
		MatrixType type = new MatrixType(x.type.getFactor(),row.index.homogeneousIndexType(),column.index.homogeneousIndexType());
		Matrix matrix = new Matrix(type, row.index, column.index);
		matrix.putDouble(row.index.ElementPos(row.names), column.index.ElementPos(column.names), x.numbers.get(0,0));
		return matrix;
	}

	public PacioliValue isolate(Key row, Key column) throws IOException {
		int i = row.index.ElementPos(row.names);
		int j = column.index.ElementPos(column.names);
		Matrix matrix = new Matrix(type, rowIndex, columnIndex);
		matrix.putDouble(i, j, numbers.get(i, j));
		return matrix;
	}

	public boolean less(Matrix other) {
		if (this.isZero() && other.isZero()) {
			return true;
		}
		if (this.isZero()) {
			for (int i=0; i<numbers.numRows(); i++) {
				for (int j=0; j<numbers.numCols(); j++) {
					if (0 > other.numbers.get(i, j)) {
						return false;
					}	
				}
			}
			return true;
		}
		if (other.isZero()) {
			for (int i=0; i<numbers.numRows(); i++) {
				for (int j=0; j<numbers.numCols(); j++) {
					if (numbers.get(i, j) > 0) {
						return false;
					}	
				}
			}
			return true;
		}
		for (int i=0; i<numbers.numRows(); i++) {
			for (int j=0; j<numbers.numCols(); j++) {
				if (numbers.get(i, j) > other.numbers.get(i, j)) {
					return false;
				}	
			}
		}
		return true;
	}

}
package mvm.values.matrix;

import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import mvm.Tokenizer;
import mvm.values.Key;
import mvm.values.PacioliList;
import mvm.values.PacioliValue;

import org.apache.commons.math.linear.OpenMapRealMatrix;
import org.apache.commons.math.linear.RealMatrix;
import org.apache.commons.math.linear.RealVector;

import units.PowerProduct;
import units.Unit;


public class Matrix implements PacioliValue {

	private MatrixType type;
	private Index rowIndex;
	private Index columnIndex;
	//private SimpleMatrix numbers;
	private RealMatrix numbers;

	////////////////////////////////////////////////////////////////////////////
	// Constructors

	public Matrix(Double num) throws IOException{
		IndexType empty = new IndexType();
		Index index = new Index(empty ,null,null);
		MatrixType singletonType = new MatrixType(new PowerProduct(),empty,empty);
		type = singletonType;
		rowIndex = index;
		columnIndex = index;
		//numbers = new SimpleMatrix(1,1);
		//numbers.set(0, 0, num);
		numbers = new OpenMapRealMatrix(rowIndex.size(),columnIndex.size());
		numbers.setEntry(0, 0, num);
	}
	
	public Matrix(MatrixType type, Index rowIndex, Index columnIndex){
		this.type = type;
		this.rowIndex = rowIndex;
		this.columnIndex = columnIndex;
		//numbers = new SimpleMatrix(rowIndex.size(),columnIndex.size());
		numbers = new OpenMapRealMatrix(rowIndex.size(),columnIndex.size());
	}

	////////////////////////////////////////////////////////////////////////////
	// Printing
	
	public String pprint() {
		if (isZero()) {
			return "0";
		}
		Unit uno = new PowerProduct();
		if (type.rowOrder() == 0 && type.columnOrder() == 0) {
			if (unitAt(0,0).equals(uno)) {
				//return String.format("%f", numbers.get(0,0));
				return String.format("%f", numbers.getEntry(0,0));
			} else {
				//return String.format("%f %s", numbers.get(0,0), unitAt(0,0).pprint());
				return String.format("%f %s", numbers.getEntry(0,0), unitAt(0,0).pprint());
			}				
		} else {
			String output = "";
			//String output = "----------------------------------------------------------------------------------";
			output += String.format("\n %50s %20s", "index", "value");
			output += "\n----------------------------------------------------------------------------------";
			Number num;
			Unit unit;
			for (int i=0; i<rowIndex.size(); i++){
				for (int j=0; j<columnIndex.size(); j++){
					//num = numbers.get(i,j);
					num = numbers.getEntry(i,j);
					if (num.doubleValue() != 0) {
						List<String> idx = new ArrayList<String>();
						idx.addAll(rowIndex.ElementAt(i));
						idx.addAll(columnIndex.ElementAt(j));
						unit = unitAt(i,j);
						if (unit.equals(uno)) {
							output += String.format("\n %50s %20f", idx, num);
						} else {
							output += String.format("\n %50s %20f %s", idx, num, unit.pprint());
						}
	//					output += String.format("\n %40s %40s %20f %s",
	//							rowIndex.ElementAt(i), columnIndex.ElementAt(j), num, unitAt(i,j).pprint());
					}
				}
			}
//			} else {
//				Number num;
//				Unit unit;
//				for (int i=0; i<rowIndex.size(); i++){
//					for (int j=0; j<columnIndex.size(); j++){
//						//num = numbers.get(i,j);
//						num = numbers.getEntry(i,j);
//						if (num.doubleValue() != 0) {
//							List<String> idx = new ArrayList<String>();
//							idx.addAll(rowIndex.ElementAt(i));
//							idx.addAll(columnIndex.ElementAt(j));
//							unit = unitAt(i,j);
//							if (unit.equals(uno)) {
//								output += String.format("\n%s %f", idx, num);
//							} else {
//								output += String.format("\n %50s %20f %s", idx, num, unit.pprint());
//							}
//		//					output += String.format("\n %40s %40s %20f %s",
//		//							rowIndex.ElementAt(i), columnIndex.ElementAt(j), num, unitAt(i,j).pprint());
//						}
//					}
//				}
			return output;
		}
	}

	public String typeString() {
		return type.pprint();
	}
	
	////////////////////////////////////////////////////////////////////////////
	// Equality

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
			//return this.numbers.isIdentical(otherMatrix.numbers, 0.0);
			return this.numbers.equals(otherMatrix.numbers);
		}
	}

	////////////////////////////////////////////////////////////////////////////
	// Utilities

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

	private Unit unitAt(int i, int j) {
		return type.getFactor().multiply(rowIndex.unitAt(i).multiply(columnIndex.unitAt(j).raise(-1)));		
	}

	public boolean isZero() {
//		for (int i=0; i<numbers.numRows(); i++) {
//			for (int j=0; j<numbers.numCols(); j++) {
//				Double entry = numbers.get(i, j);
//		for (int i=0; i<numbers.getRowDimension(); i++) {
//			for (int j=0; j<numbers.getColumnDimension(); j++) {
//				Double entry = numbers.getEntry(i, j);
//				if (entry != 0) {
//					return false;	
//				}	
//			}
//		}
		Iterator<RealVector.Entry> iterator;
		RealVector.Entry entry;
		for (int i=0; i<numbers.getRowDimension(); i++) {
			iterator = numbers.getRowVector(i).sparseIterator();
			while (iterator.hasNext()) {
				entry = (RealVector.Entry) iterator.next();
				if (entry.getValue() != 0.0) {
					return false;
				}
			}
		}

		return true;
	}

	private static RealMatrix identityNumbers(int size) {
		RealMatrix numbers = new OpenMapRealMatrix(size, size);
		for (int i=0; i<size; i++) {
			numbers.setEntry(i, i, 1);
		}
		return numbers;
	}
		
	////////////////////////////////////////////////////////////////////////////
	// Matrix manipulation
	
	
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


	public PacioliList rowDomain() {
		List<PacioliValue> keys = new ArrayList<PacioliValue>();
		for (Key key: rowKeys()) {
			keys.add(key);
		}
		return new PacioliList(keys);
	}
	
	public PacioliList columnDomain() {
		List<PacioliValue> keys = new ArrayList<PacioliValue>();
		for (Key key: columnKeys()) {
			keys.add(key);
		}
		return new PacioliList(keys);
	}

	public PacioliValue get(Key row, Key column) throws IOException {
		IndexType empty = new IndexType();
		Index index = new Index(empty ,null,null);
		MatrixType entryType = new MatrixType(type.getFactor(),empty,empty);
		Matrix matrix = new Matrix(entryType, index, index);
		//matrix.numbers.set(0, 0, numbers.get(rowIndex.ElementPos(row.names), columnIndex.ElementPos(column.names)));
		matrix.numbers.setEntry(0, 0, numbers.getEntry(rowIndex.ElementPos(row.names), columnIndex.ElementPos(column.names)));
		return matrix;
	}

	public PacioliValue magnitude(Key row, Key column) throws IOException {
		IndexType empty = new IndexType();
		Index index = new Index(empty ,null,null);
		MatrixType entryType = new MatrixType(new PowerProduct(),empty,empty);
		Matrix matrix = new Matrix(entryType, index, index);
//		if (isZero()) {
//			matrix.numbers.set(0, 0, 0);
//		} else {
//			matrix.numbers.set(0, 0, numbers.get(rowIndex.ElementPos(row.names), columnIndex.ElementPos(column.names)));
//		}
		if (isZero()) {
			matrix.numbers.setEntry(0, 0, 0);
		} else {
			matrix.numbers.setEntry(0, 0, numbers.getEntry(rowIndex.ElementPos(row.names), columnIndex.ElementPos(column.names)));
		}
		return matrix;
	}

	public Matrix putDouble(int i, int j, Double value) {
		//numbers.set(i, j, value);
		numbers.setEntry(i, j, value);
		return this;
	}

	public PacioliValue put(Key row, Key column, Matrix value) throws IOException {
		Matrix matrix = new Matrix(type, rowIndex, columnIndex);
		matrix.numbers = numbers.copy();
		//matrix.putDouble(row.index.ElementPos(row.names), column.index.ElementPos(column.names), value.numbers.get(0,0));
		matrix.putDouble(row.index.ElementPos(row.names), column.index.ElementPos(column.names), value.numbers.getEntry(0,0));
		return matrix;
	}
	

	public PacioliValue set(Key row, Key column, Matrix x) throws IOException {
		MatrixType type = new MatrixType(x.type.getFactor(),row.index.homogeneousIndexType(),column.index.homogeneousIndexType());
		Matrix matrix = new Matrix(type, row.index, column.index);
		//matrix.putDouble(row.index.ElementPos(row.names), column.index.ElementPos(column.names), x.numbers.get(0,0));
		matrix.putDouble(row.index.ElementPos(row.names), column.index.ElementPos(column.names), x.numbers.getEntry(0,0));
		return matrix;
	}

	public PacioliValue isolate(Key row, Key column) throws IOException {
		int i = row.index.ElementPos(row.names);
		int j = column.index.ElementPos(column.names);
		Matrix matrix = new Matrix(type, rowIndex, columnIndex);
		//matrix.putDouble(i, j, numbers.get(i, j));
		matrix.putDouble(i, j, numbers.getEntry(i, j));
		return matrix;
	}

	private List<PacioliValue> columnRange(int from, int to) throws IOException {
		List<PacioliValue> columns = new ArrayList<PacioliValue>();
		MatrixType extractedType = type.extractColumn();
		Index index = new Index(new IndexType(),null,null);
		for (int i=from; i < to; i++) {
			Matrix matrix = new Matrix(extractedType, rowIndex, index);
			matrix.numbers = numbers.getColumnMatrix(i);
			columns.add(matrix);
		}
		return columns;
	}
	
	public PacioliValue column(Key key) throws IOException {
		int position = columnIndex.ElementPos(key.names);
		return columnRange(position,position+1).get(0);	
	}
	
	public PacioliList columns() throws IOException {
		//List<PacioliValue> columns = new ArrayList<PacioliValue>();
//		MatrixType extractedType = type.extractColumn();
//		Index index = new Index(new IndexType(),null,null);
//		//for (int i=0; i < numbers.numCols(); i++) {
//		for (int i=0; i < numbers.getColumnDimension(); i++) {
//			Matrix matrix = new Matrix(extractedType, rowIndex, index);
//			//matrix.numbers = numbers.extractVector(false, i);
//			matrix.numbers = numbers.getColumnMatrix(i);
//			columns.add(matrix);
//		}
//		return columns;
		
		
		//List<PacioliValue> columns = new ArrayList<PacioliValue>();
//		for (Matrix mat: columnRange(0, numbers.getColumnDimension())) {
//			columns.add(mat);
//		}
		return new PacioliList(columnRange(0, numbers.getColumnDimension()));	
		
		
	}

	private List<PacioliValue> rowRange(int from, int to) throws IOException {
		List<PacioliValue> rows = new ArrayList<PacioliValue>();
		MatrixType extractedType = type.extractRow();
		Index index = new Index(new IndexType(),null,null);
		for (int i=from; i < to; i++) {
			Matrix matrix = new Matrix(extractedType, index, columnIndex);
			matrix.numbers = numbers.getRowMatrix(i);
			rows.add(matrix);
		}
		return rows;
	}
	
	public PacioliValue row(Key key) throws IOException {
		int position = rowIndex.ElementPos(key.names);
		return rowRange(position,position+1).get(0);	
	}
	
	public PacioliList rows() throws IOException {
		return new PacioliList(rowRange(0, numbers.getRowDimension()));	
	}

	////////////////////////////////////////////////////////////////////////////
	// Reading and Writing

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
			//numbers.set(rowIndex.ElementPos(row), columnIndex.ElementPos(column), num);
			numbers.setEntry(rowIndex.ElementPos(row), columnIndex.ElementPos(column), num);
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

					//numbers.set(i, j, 1.0);
					numbers.setEntry(i, j, 1.0);
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
				//numbers.set(i,i, num);
				numbers.setEntry(i,i, num);
			}
		}
	}

	public void writeConspiracy(List<String> rowKey, BufferedWriter stream) throws IOException {
				
		for (int i=0; i<numbers.getRowDimension(); i++) {
			for (int j=0; j<numbers.getColumnDimension(); j++) {
				if (numbers.getEntry(i, j) != 0.0) {
					for (String key: rowIndex.ElementAt(i)) {
						stream.write(String.format("\"%s\" ", key));
					}
					for (String key: rowKey) {
						stream.write(String.format("\"%s\" ", key));
					}
					stream.write(String.format("%s;\n", numbers.getEntry(i, j)));
				}	
			}
		}
//		Iterator<RealVector.Entry> iterator;
//		RealVector.Entry entry;
//		iterator = numbers.getRowVector(0).sparseIterator();
//		while (iterator.hasNext()) {
//			entry = (RealVector.Entry) iterator.next();
//			if (entry.getValue() != 0.0) {
//				for (String key: rowKey) {
//					stream.write(String.format("\"%s\" ", key));
//				}
//				for (String key: columnIndex.ElementAt(entry.getIndex())) {
//					stream.write(String.format("\"%s\" ", key));
//				}
//				stream.write(String.format("%s;\n", entry.getValue()));
//			}
//		}
	}
	
	////////////////////////////////////////////////////////////////////////////
	// Mathematical Operations

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
			//matrix.numbers = numbers.plus(other.numbers);
			matrix.numbers = numbers.add(other.numbers);
			return matrix;
		} else {
			throw new IOException("types '" + type.pprint() + "' and '" + other.type.pprint() + "' not equal in sum");
		}
	}

	public Matrix multiply(Matrix other) throws IOException{
		int m = numbers.getRowDimension();
		int n = numbers.getColumnDimension();
		if (type.multiplyable(other.type)) {
			Matrix matrix = new Matrix(type.multiply(other.type), rowIndex.multiply(other.rowIndex), columnIndex.multiply(other.columnIndex));
			//matrix.numbers = numbers.elementMult(other.numbers);
			matrix.numbers = new OpenMapRealMatrix(m, n);
			for (int i=0; i < m; i++) {
				for (int j=0; j < n; j++) {
					matrix.numbers.setEntry(i, j, numbers.getEntry(i, j) * other.numbers.getEntry(i, j));
				}
			}
			return matrix;
		} else {
			throw new IOException("types '" + type.pprint() + "' and '" + other.type.pprint() + "' not compatible for multiplication");
		}
	}
	
	public Matrix negative() {
		Matrix matrix = new Matrix(type, rowIndex, columnIndex);
		//matrix.numbers = numbers.negative();
		matrix.numbers = numbers.scalarMultiply(-1);
		return matrix;
	}

	public Matrix reciprocal() {
		Matrix matrix = new Matrix(type.reciprocal(), rowIndex.reciprocal(), columnIndex.reciprocal());
//		for (int i=0; i<numbers.numRows(); i++) {
//			for (int j=0; j<numbers.numCols(); j++) {
//				Double numerator = numbers.get(i, j);
		for (int i=0; i<numbers.getRowDimension(); i++) {
			for (int j=0; j<numbers.getColumnDimension(); j++) {
				Double numerator = numbers.getEntry(i, j);				
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
			//matrix.numbers = numbers.mult(other.numbers);
			matrix.numbers = numbers.multiply(other.numbers);
			return matrix;
		} else {
			throw new IOException("types '" + type.pprint() + "' and '" + other.type.pprint() + "' not compatible for joining");
		}
	}

	public Matrix closure() throws IOException {
		if (type.unitSquare()) {
			Matrix matrix = new Matrix(type, rowIndex, columnIndex);
			//SimpleMatrix ident = SimpleMatrix.identity(rowIndex.size());
			//matrix.numbers = ident.minus(numbers).invert().minus(ident);
			RealMatrix ident = identityNumbers(rowIndex.size());
			matrix.numbers = ident.subtract(numbers).inverse().subtract(ident);
			return matrix; 
		} else {
			throw new IOException("type '" + type.pprint() + "' not square when taking closure");
		}
	}

	public Matrix kleene() throws IOException {
		if (type.unitSquare()) {
			Matrix matrix = new Matrix(type, rowIndex, columnIndex);
			//SimpleMatrix ident = SimpleMatrix.identity(rowIndex.size());
			//matrix.numbers = ident.minus(numbers).invert();
			RealMatrix ident = identityNumbers(rowIndex.size());
			matrix.numbers = ident.subtract(numbers).inverse();
			return matrix; 
		} else {
			throw new IOException("type '" + type.pprint() + "' not square when taking kleene closure");
		}
	}

	public PacioliValue scale(Matrix other) throws IOException {
		if (type.singleton()) {
			Matrix matrix = new Matrix(type.scale(other.type), other.rowIndex, other.columnIndex);
			//matrix.numbers = other.numbers.scale(numbers.get(0,0));
			matrix.numbers = other.numbers.scalarMultiply(numbers.getEntry(0,0));
			return matrix;
		} else {
			throw new IOException("types '" + type.pprint() + "' and '" + other.type.pprint() + "' not compatible for scaling");
		}
	}

	public PacioliValue leftIdentity() {
		MatrixType identityType = type.leftIdentity();
		Matrix matrix = new Matrix(identityType, rowIndex, rowIndex);
//		for (int i=0; i < numbers.numRows(); i++) {
//			matrix.numbers.set(i, i, 1.0);
//		}
		for (int i=0; i < numbers.getRowDimension(); i++) {
			matrix.numbers.setEntry(i, i, 1.0);
		}
		return matrix;
	}
	
	public PacioliValue rightIdentity() {
		MatrixType identityType = type.rightIdentity();
		Matrix matrix = new Matrix(identityType, columnIndex, columnIndex);
//		for (int i=0; i < numbers.numCols(); i++) {
//			matrix.numbers.set(i, i, 1.0);
//		}
		for (int i=0; i < numbers.getColumnDimension(); i++) {
			matrix.numbers.setEntry(i, i, 1.0);
		}
		return matrix;
	}
	
	public Matrix total() throws IOException {
		IndexType empty = new IndexType();
		Index index = new Index(empty ,null,null);
		MatrixType totalType = new MatrixType(type.getFactor(),empty,empty);
		Matrix matrix = new Matrix(totalType, index, index);
		//matrix.numbers.set(0, 0, numbers.elementSum());
		double sum = 0;
		for (int i=0; i < numbers.getRowDimension(); i++) {
			for (int j=0; j < numbers.getColumnDimension(); j++) {
				sum += matrix.numbers.getEntry(i, j);
			}
		}
		matrix.numbers.setEntry(0, 0, sum);
		return matrix; 
	}
	
	public boolean less(Matrix other) {
		if (this.isZero() && other.isZero()) {
			return false;
		}
		//RealVector row;
		Iterator<RealVector.Entry> iterator1;
		Iterator<RealVector.Entry> iterator2;
		RealVector.Entry entry;
		for (int i=0; i<numbers.getRowDimension(); i++) {
			iterator1 = numbers.getRowVector(i).sparseIterator();
			iterator2 = other.numbers.getRowVector(i).sparseIterator();
			while (iterator1.hasNext() && iterator2.hasNext()) {
				entry = (RealVector.Entry) iterator1.next();
				System.out.println(String.format("%s %s %s", i, entry.getIndex(), entry.getValue()));
			}
			
		}
//		OpenMapRealVector ns = ((OpenMapRealVector) numbers);
//		ns.sparseIterator();
		if (this.isZero()) {
//			for (int i=0; i<numbers.numRows(); i++) {
//				for (int j=0; j<numbers.numCols(); j++) {
//					if (0 >= other.numbers.get(i, j)) {
			for (int i=0; i<numbers.getRowDimension(); i++) {
				for (int j=0; j<numbers.getColumnDimension(); j++) {
					if (0 >= other.numbers.getEntry(i, j)) {
						return false;
					}	
				}
			}
			return true;
		}
		if (other.isZero()) {
//			for (int i=0; i<numbers.numRows(); i++) {
//				for (int j=0; j<numbers.numCols(); j++) {
//					if (numbers.get(i, j) >= 0) {
			for (int i=0; i<numbers.getRowDimension(); i++) {
				for (int j=0; j<numbers.getColumnDimension(); j++) {
					if (numbers.getEntry(i, j) >= 0) {
						return false;
					}	
				}
			}
			return true;
		}
//		for (int i=0; i<numbers.numRows(); i++) {
//			for (int j=0; j<numbers.numCols(); j++) {
//				if (numbers.get(i, j) >= other.numbers.get(i, j)) {
		for (int i=0; i<numbers.getRowDimension(); i++) {
			for (int j=0; j<numbers.getColumnDimension(); j++) {
				if (numbers.getEntry(i, j) >= other.numbers.getEntry(i, j)) {
					return false;
				}	
			}
		}
		return true;
	}

	public boolean lessEq(Matrix other) {
		/*
		if (this.isZero() && other.isZero()) {
			return true;
		}
		if (this.isZero()) {
//			for (int i=0; i<numbers.numRows(); i++) {
//				for (int j=0; j<numbers.numCols(); j++) {
//					if (0 > other.numbers.get(i, j)) {
			for (int i=0; i<numbers.getRowDimension(); i++) {
				for (int j=0; j<numbers.getColumnDimension(); j++) {
					if (0 > other.numbers.getEntry(i, j)) {
						return false;
					}	
				}
			}
			return true;
		}
		if (other.isZero()) {
//			for (int i=0; i<numbers.numRows(); i++) {
//				for (int j=0; j<numbers.numCols(); j++) {
//					if (numbers.get(i, j) > 0) {
			for (int i=0; i<numbers.getRowDimension(); i++) {
				for (int j=0; j<numbers.getColumnDimension(); j++) {
					if (numbers.getEntry(i, j) > 0) {
						return false;
					}	
				}
			}
			return true;
		}
//		for (int i=0; i<numbers.numRows(); i++) {
//			for (int j=0; j<numbers.numCols(); j++) {
//				if (numbers.get(i, j) > other.numbers.get(i, j)) {
		for (int i=0; i<numbers.getRowDimension(); i++) {
			for (int j=0; j<numbers.getColumnDimension(); j++) {
				if (numbers.getEntry(i, j) > other.numbers.getEntry(i, j)) {
					return false;
				}	
			}
		}*/
		Iterator<RealVector.Entry> iterator;
		RealVector.Entry entry;
		boolean isZero = isZero();
		boolean otherIsZero = other.isZero();
		if (isZero && otherIsZero) {
			return true;
		}
		if (otherIsZero) {
			for (int i=0; i<numbers.getRowDimension(); i++) {
				iterator = numbers.getRowVector(i).sparseIterator();
				while (iterator.hasNext()) {
					entry = iterator.next();
					if (entry.getValue() > 0) {
						return false;
					}
				}
			}
			return true;
		}
		if (isZero) {
			for (int i=0; i<other.numbers.getRowDimension(); i++) {
				iterator = other.numbers.getRowVector(i).sparseIterator();
				while (iterator.hasNext()) {
					entry = iterator.next();
					if (entry.getValue() < 0) {
						return false;
					}
				}
			}
			return true;
		}
		for (int i=0; i<numbers.getRowDimension(); i++) {
			iterator = numbers.getRowVector(i).sparseIterator();
			while (iterator.hasNext()) {
				entry = (RealVector.Entry) iterator.next();
				if (entry.getValue() > other.numbers.getEntry(i, entry.getIndex())) {
					return false;
				}
			}
		}
		for (int i=0; i<other.numbers.getRowDimension(); i++) {
			iterator = other.numbers.getRowVector(i).sparseIterator();
			while (iterator.hasNext()) {
				entry = (RealVector.Entry) iterator.next();
				if (entry.getValue() < numbers.getEntry(i, entry.getIndex())) {
					return false;
				}
			}
		}
		return true;
	}

	public PacioliValue gcd(Matrix other) throws IOException {
//		int a = (int) numbers.get(0,0);
//		int b = (int) other.numbers.get(0,0);
		int a = (int) numbers.getEntry(0,0);
		int b = (int) other.numbers.getEntry(0,0);
		if (a < 0) {
			a = -a;
		}
		if (b < 0) {
			b = -b;
		}
		while (b != 0 && a != 0) {
			if (a > b) {
				a = a % b;
			} else {
		        b = b % a;
			}
		}
		if (a == 0) {
			a = b;
		}
		IndexType empty = new IndexType();
		Index index = new Index(empty ,null,null);
		MatrixType entryType = new MatrixType(new PowerProduct(),empty,empty);
		Matrix matrix = new Matrix(entryType, index, index);
		//matrix.numbers.set(0, 0, a);
		matrix.numbers.setEntry(0, 0, a);
		return matrix;		
	}

	public PacioliValue abs() {
		Matrix matrix = new Matrix(type, rowIndex, columnIndex);
//		for (int i=0; i<numbers.numRows(); i++) {
//			for (int j=0; j<numbers.numCols(); j++) {
//				Double value = numbers.get(i, j);		
		for (int i=0; i<numbers.getRowDimension(); i++) {
			for (int j=0; j<numbers.getColumnDimension(); j++) {
				Double value = numbers.getEntry(i, j);
				if (value < 0) {
					matrix.putDouble(i,j,-value);	
				} else {
					matrix.putDouble(i,j,value);
				}
			}
		}
		return matrix;
	}

	public Matrix div(Matrix other) throws IOException {
		IndexType empty = new IndexType();
		Index index = new Index(empty ,null,null);
		MatrixType entryType = new MatrixType(new PowerProduct(),empty,empty);
		Matrix matrix = new Matrix(entryType, index, index);
//		int a = (int) numbers.get(0,0);
//		int b = (int) other.numbers.get(0,0);
//		matrix.numbers.set(0, 0, a/b);
		int a = (int) numbers.getEntry(0,0);
		int b = (int) other.numbers.getEntry(0,0);
		matrix.numbers.setEntry(0, 0, a/b);
		return matrix;
	}

	public Matrix mod(Matrix other) throws IOException {
		IndexType empty = new IndexType();
		Index index = new Index(empty ,null,null);
		MatrixType entryType = new MatrixType(new PowerProduct(),empty,empty);
		Matrix matrix = new Matrix(entryType, index, index);
//		int a = (int) numbers.get(0,0);
//		int b = (int) other.numbers.get(0,0);
//		matrix.numbers.set(0, 0, a%b);		
		int a = (int) numbers.getEntry(0,0);
		int b = (int) other.numbers.getEntry(0,0);
		matrix.numbers.setEntry(0, 0, a%b);
		return matrix;
	}

	public PacioliValue support() throws IOException {
		MatrixType supportType = type.multiply(type.reciprocal());
		Matrix matrix = new Matrix(supportType,
								   rowIndex.multiply(rowIndex.reciprocal()),
								   columnIndex.multiply(columnIndex.reciprocal()));
//		for (int i=0; i < numbers.numRows(); i++) {
//			matrix.numbers.set(i, i, 1.0);
//		}
		Iterator<RealVector.Entry> iterator;
		RealVector.Entry entry;
		for (int i=0; i<numbers.getRowDimension(); i++) {
			iterator = numbers.getRowVector(i).sparseIterator();
			while (iterator.hasNext()) {
				entry = (RealVector.Entry) iterator.next();
				if (entry.getValue() != 0.0) {
					matrix.numbers.setEntry(i, entry.getIndex(), 1.0);
				}
			}
		}
		return matrix;	
	}
}
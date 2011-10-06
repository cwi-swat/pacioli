package mvm.values.matrix;

import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import mvm.Reader;
import mvm.values.Key;
import mvm.values.PacioliList;
import mvm.values.PacioliValue;

import org.apache.commons.math.fraction.BigFraction;

import units.Unit;


public class Matrix implements PacioliValue {

	private MatrixType type;
	private Index rowIndex;
	private Index columnIndex;
	private MatrixNumbers numbers;

	////////////////////////////////////////////////////////////////////////////
	// Constructors

	public Matrix(int num) throws IOException{
		type = new MatrixType();
		rowIndex = new Index();
		columnIndex = new Index();
		numbers = new MatrixNumbers(rowIndex.size(), columnIndex.size());
		numbers.set(0, 0, num);
	}

	public Matrix(double num) throws IOException{
		type = new MatrixType();
		rowIndex = new Index();
		columnIndex = new Index();
		numbers = new MatrixNumbers(rowIndex.size(), columnIndex.size());
		numbers.set(0, 0, num);
	}
	
	public Matrix(BigFraction num) throws IOException{
		type = new MatrixType();
		rowIndex = new Index();
		columnIndex = new Index();
		numbers = new MatrixNumbers(rowIndex.size(), columnIndex.size());
		numbers.set(0, 0, num);
	}

	public Matrix(Unit unit) throws IOException{
		type = new MatrixType(unit, new IndexType(), new IndexType());
		rowIndex = new Index();
		columnIndex = new Index();
		numbers = new MatrixNumbers(rowIndex.size(), columnIndex.size());
		numbers.set(0, 0, 1);
	}

	public Matrix(MatrixType type, Index rowIndex, Index columnIndex){
		this.type = type;
		this.rowIndex = rowIndex;
		this.columnIndex = columnIndex;
		numbers = new MatrixNumbers(rowIndex.size(), columnIndex.size());
	}

	////////////////////////////////////////////////////////////////////////////
	// Printing
	
	public String pprint() {
		
		if (isZero()) {
			return "0";
		}
		
		if (type.rowOrder() == 0 && type.columnOrder() == 0) {
			if (unitAt(0,0).equals(Unit.ONE)) {
				return String.format("%s", numbers.get(0,0).bigDecimalValue());
			} else {
				return String.format("%s %s", numbers.get(0,0).bigDecimalValue(), unitAt(0,0).pprint());
			}				
		} 
		
		BigFraction num;
		Unit unit;
		String output = "";
		
		output += String.format("\n %50s %20s", "index", "value");
		output += "\n----------------------------------------------------------------------------------";
		for (int i=0; i < rowIndex.size(); i++) {
			for (int j=0; j < columnIndex.size(); j++) {
				num = numbers.get(i,j);
				if (num.compareTo(BigFraction.ZERO) != 0) {
					List<String> idx = new ArrayList<String>();
					idx.addAll(rowIndex.ElementAt(i));
					idx.addAll(columnIndex.ElementAt(j));
					unit = unitAt(i,j);
					if (unit.equals(Unit.ONE)) {
						output += String.format("\n %50s %20s", idx, num.bigDecimalValue());
					} else {
						output += String.format("\n %50s %20s %s", idx, num.bigDecimalValue(), unit.pprint());
					}
				}
			}
		}
		
		return output;
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
		return numbers.hashCode();
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
		return numbers.isZero();
	}

	////////////////////////////////////////////////////////////////////////////
	// Matrix manipulation
	
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

	// Moet de unit niet mee?
	public PacioliValue get(Key row, Key column) throws IOException {
		return new Matrix(numbers.get(rowIndex.ElementPos(row.names), columnIndex.ElementPos(column.names)));
	}

	// Kan weg!?
	public PacioliValue magnitude(Key row, Key column) throws IOException {
		return get(row,column);
	}

	public PacioliValue put(Key row, Key column, Matrix value) throws IOException {
		int i = row.index.ElementPos(row.names);
		int j = column.index.ElementPos(column.names);
		Matrix matrix = new Matrix(type, rowIndex, columnIndex);
		matrix.numbers = numbers.copy();
		matrix.numbers.set(i, j, value.numbers.get(0,0));
		return matrix;
	}
	

	public PacioliValue set(Key row, Key column, Matrix value) throws IOException {
		int i = row.index.ElementPos(row.names);
		int j = column.index.ElementPos(column.names);
		MatrixType type = new MatrixType(value.type.getFactor(), row.index.homogeneousIndexType(), column.index.homogeneousIndexType());
		Matrix matrix = new Matrix(type, row.index, column.index);
		matrix.numbers.set(i, j, value.numbers.get(0,0));
		return matrix;
	}

	public PacioliValue isolate(Key row, Key column) throws IOException {
		int i = row.index.ElementPos(row.names);
		int j = column.index.ElementPos(column.names);
		Matrix matrix = new Matrix(type, rowIndex, columnIndex);
		matrix.numbers.set(i, j, numbers.get(i,j));
		return matrix;
	}

	private List<PacioliValue> columnRange(int from, int to) throws IOException {
		List<PacioliValue> columns = new ArrayList<PacioliValue>();
		MatrixType extractedType = type.extractColumn();
		Index index = new Index(new IndexType(),null,null);
		for (int i=from; i < to; i++) {
			Matrix matrix = new Matrix(extractedType, rowIndex, index);
			matrix.numbers = numbers.getColumn(i);
			columns.add(matrix);
		}
		return columns;
	}
	
	public PacioliValue column(Key key) throws IOException {
		int position = columnIndex.ElementPos(key.names);
		return columnRange(position,position+1).get(0);	
	}
	
	public PacioliList columns() throws IOException {
		return new PacioliList(columnRange(0, columnIndex.size()));	
	}

	private List<PacioliValue> rowRange(int from, int to) throws IOException {
		List<PacioliValue> rows = new ArrayList<PacioliValue>();
		MatrixType extractedType = type.extractRow();
		Index index = new Index(new IndexType(),null,null);
		for (int i=from; i < to; i++) {
			Matrix matrix = new Matrix(extractedType, index, columnIndex);
			matrix.numbers = numbers.getRow(i);
			rows.add(matrix);
		}
		return rows;
	}
	
	public PacioliValue row(Key key) throws IOException {
		int position = rowIndex.ElementPos(key.names);
		return rowRange(position,position+1).get(0);	
	}
	
	public PacioliList rows() throws IOException {
		return new PacioliList(rowRange(0, rowIndex.size()));	
	}

	////////////////////////////////////////////////////////////////////////////
	// Reading and Writing

	public void load(String source) throws IOException {
		
		int rowWidth = rowIndex.width();
		int columnWidth = columnIndex.width();
		
		Reader tokenizer = new Reader(new FileReader(source), null);
		while (!tokenizer.eof()) {
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
			//double num = tokenizer.readNumber().doubleValue();
			BigFraction num = tokenizer.readNumber();
			numbers.set(rowIndex.ElementPos(row), columnIndex.ElementPos(column), num);
			tokenizer.readSeparator();
		}
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

					numbers.set(i, j, 1);
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

	public void writeConspiracy(List<String> rowKey, BufferedWriter stream) throws IOException {
		for (int i=0; i < rowIndex.size(); i++) {
			for (int j=0; j < columnIndex.size(); j++) {
				if (numbers.get(i, j).compareTo(BigFraction.ZERO) != 0) {
					for (String key: rowIndex.ElementAt(i)) {
						stream.write(String.format("\"%s\" ", key));
					}
					for (String key: rowKey) {
						stream.write(String.format("\"%s\" ", key));
					}
					stream.write(String.format("%s;\n", numbers.get(i, j).toString()));
				}	
			}
		}
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
			matrix.numbers = numbers.add(other.numbers);
			return matrix;
		} else {
			throw new IOException("types '" + type.pprint() + "' and '" + other.type.pprint() + "' not equal in sum");
		}
	}

	public Matrix multiply(Matrix other) throws IOException{
		if (type.multiplyable(other.type)) {
			Matrix matrix = new Matrix(type.multiply(other.type), rowIndex.multiply(other.rowIndex), columnIndex.multiply(other.columnIndex));
			matrix.numbers = numbers.multiply(other.numbers);
			return matrix;
		} else {
			throw new IOException("types '" + type.pprint() + "' and '" + other.type.pprint() + "' not compatible for multiplication");
		}
	}
	
	public Matrix negative() {
		Matrix matrix = new Matrix(type, rowIndex, columnIndex);
		matrix.numbers = numbers.scale(new BigFraction(-1));
		return matrix;
	}

	public Matrix reciprocal() {
		Matrix matrix = new Matrix(type.reciprocal(), rowIndex.reciprocal(), columnIndex.reciprocal());
		matrix.numbers = numbers.reciprocal();
		return matrix;
	}
	
	public Matrix join(Matrix other) throws IOException{
		if (type.joinable(other.type)) {
			Matrix matrix = new Matrix(type.join(other.type), rowIndex, other.columnIndex);
			matrix.numbers = numbers.join(other.numbers);
			return matrix;
		} else {
			throw new IOException("types '" + type.pprint() + "' and '" + other.type.pprint() + "' not compatible for joining");
		}
	}

	public Matrix closure() throws IOException {
		if (type.unitSquare()) {
			Matrix matrix = new Matrix(type, rowIndex, columnIndex);
			matrix.numbers = numbers.closure();
			return matrix; 
		} else {
			throw new IOException("type '" + type.pprint() + "' not square when taking closure");
		}
	}

	public Matrix kleene() throws IOException {
		if (type.unitSquare()) {
			Matrix matrix = new Matrix(type, rowIndex, columnIndex);
			matrix.numbers = numbers.kleene();
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
		matrix.numbers = MatrixNumbers.identityNumbers(rowIndex.size());
		return matrix;
	}
	
	public PacioliValue rightIdentity() {
		MatrixType identityType = type.rightIdentity();
		Matrix matrix = new Matrix(identityType, columnIndex, columnIndex);
		matrix.numbers = MatrixNumbers.identityNumbers(columnIndex.size());
		return matrix;
	}
	
	public Matrix total() throws IOException {
		Matrix matrix = new Matrix(type.getFactor());
		matrix.numbers.scale(numbers.total());
		return matrix; 
	}
	
	public boolean less(Matrix other) {
		return numbers.less(other.numbers);
	}

	public boolean lessEq(Matrix other) {
		return numbers.lessEq(other.numbers);
	}

	public PacioliValue gcd(Matrix other) throws IOException {
		int a = numbers.get(0,0).intValue();
		int b = other.numbers.get(0,0).intValue();
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
		return new Matrix(a);		
	}

	public PacioliValue abs() {
		Matrix matrix = new Matrix(type, rowIndex, columnIndex);
		matrix.numbers = numbers.abs();
		return matrix;
	}

	public Matrix div(Matrix other) throws IOException {
		Matrix matrix = new Matrix(type, rowIndex, columnIndex);
		matrix.numbers = numbers.div(other.numbers);
		return matrix;
	}

	public Matrix mod(Matrix other) throws IOException {
		Matrix matrix = new Matrix(type, rowIndex, columnIndex);
		matrix.numbers = numbers.mod(other.numbers);
		return matrix;
	}

	public PacioliValue support() throws IOException {
		MatrixType supportType = type.multiply(type.reciprocal());
		Matrix matrix = new Matrix(supportType,
								   rowIndex.multiply(rowIndex.reciprocal()),
								   columnIndex.multiply(columnIndex.reciprocal()));
		matrix.numbers = numbers.support();
		return matrix;
	}
}
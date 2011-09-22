package mvm.values.matrix;

import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import mvm.Tokenizer;
import mvm.values.PacioliValue;

import org.ejml.simple.SimpleMatrix;

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
		SimpleMatrix newNumbers = new SimpleMatrix(numbers.numRows(), numbers.numCols());
		for (int i=0; i<numbers.numRows(); i++) {
			for (int j=0; j<numbers.numCols(); j++) {
				Double numerator = numbers.get(i, j);
				if (numerator != 0) {
					newNumbers.set(i,j,1/numerator);	
				}	
			}
		}
		Matrix matrix = new Matrix(type.reciprocal(), rowIndex.reciprocal(), columnIndex.reciprocal());
		matrix.numbers = newNumbers;
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

	public Matrix total() throws IOException {
		IndexType empty = new IndexType();
		Index index = new Index(empty ,null,null);
		MatrixType totalType = new MatrixType(type.getFactor(),empty,empty);
		Matrix matrix = new Matrix(totalType, index, index);
		matrix.numbers = new SimpleMatrix(1,1);
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
		if (type.rowOrder() == 0 && type.columnOrder() == 0) {
			return String.format("%f %s", numbers.get(0,0), unitAt(0,0).pprint());
		} else {
				
			//String output = "----------------------------------------------------------------------------------";
			String output = "";
			output += String.format("\n %50s %20s", "index", "value");
			output += "\n----------------------------------------------------------------------------------";
			Number num;
			for (int i=0; i<rowIndex.size(); i++){
				for (int j=0; j<columnIndex.size(); j++){
					num = numbers.get(i,j);
					if (num.doubleValue() != 0) {
						List<String> idx = new ArrayList<String>();
						idx.addAll(rowIndex.ElementAt(i));
						idx.addAll(columnIndex.ElementAt(j));
						output += String.format("\n %50s %20f %s",
								idx, num, unitAt(i,j).pprint());
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

		numbers = new SimpleMatrix(rowIndex.size(),columnIndex.size());
		
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

		numbers = new SimpleMatrix(rowIndex.size(),columnIndex.size());

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

		numbers = new SimpleMatrix(rowIndex.size(),columnIndex.size());
		
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

	public boolean sameAs(Matrix y) {
		return this.numbers.isIdentical(y.numbers, 0.0);
	}

	public Matrix put(int i, int j, Double value) {
		numbers = new SimpleMatrix(rowIndex.size(),columnIndex.size());
		numbers.set(i, j, value);
		return this;
	}
}
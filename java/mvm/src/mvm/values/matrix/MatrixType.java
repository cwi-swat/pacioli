package mvm.values.matrix;

import units.PowerProduct;
import units.Unit;


public class MatrixType {
	
	private Unit factor;
	private IndexType rowType;
	private IndexType columnType;
	
	public MatrixType(Unit factor, IndexType rowType, IndexType columnType){
		this.factor = factor;
		this.rowType = rowType;
		this.columnType = columnType;
	}
	
	public MatrixType(Unit factor){
		this.factor = factor;
		this.rowType = new IndexType();
		this.columnType = new IndexType();
	}
	
	public MatrixType(){
		this.factor = new PowerProduct();
		this.rowType = new IndexType();
		this.columnType = new IndexType();
	}
	
	public Unit getFactor() {
		return factor;
	}

	public int hashCode() {
		return factor.hashCode();
	}
	
	public int rowOrder() {
		return rowType.width();
	}
	
	public int columnOrder() {
		return columnType.width();
	}
	
	public boolean equals(Object other) {
		if (other == this) {
			return true;
		}
		if (! (other instanceof MatrixType)) {
			return false;
		}
		MatrixType otherType = (MatrixType) other;
		if (! factor.equals(otherType.factor)) {
			return false;
		}
		if (! rowType.equals(otherType.rowType)) {
			return false;
		}
		if (! columnType.equals(otherType.columnType)) {
			return false;
		}
		return true;
	}

	public boolean unitSquare() {
		return rowType.equals(columnType);
	}

	public MatrixType transpose() {
		return new MatrixType(factor, columnType.reciprocal(), rowType.reciprocal());
	}

	public boolean multiplyable(MatrixType other) {
		return (rowType.multiplyable(other.rowType) && columnType.multiplyable(other.columnType));
	}

	public MatrixType multiply(MatrixType other){
		return new MatrixType(factor.multiply(other.factor), rowType.multiply(other.rowType), columnType.multiply(other.columnType));
	} 

	public MatrixType reciprocal(){
		return new MatrixType(factor.raise(-1), rowType.reciprocal(), columnType.reciprocal());
	}

	public boolean joinable(MatrixType other) {
		return columnType.equals(other.rowType);
	}
	
	public MatrixType join(MatrixType other){
		return new MatrixType(factor.multiply(other.factor), rowType, other.columnType);
	}

	public boolean singleton() {
		return rowOrder() == 0 && columnOrder() == 0;
	}

	public MatrixType scale(MatrixType other) {
		return new MatrixType(factor.multiply(other.factor), other.rowType, other.columnType);
	}
	
	public String pprint(){
		
		String factorString = factor.pprint();
		String rowString = rowType.pprint();
		String columnString = columnType.pprint();
		Unit one = new PowerProduct();
		
		// Dit kan beter :)
		String tail= "";
		if (! columnString.equals("Empty")) {
			tail = " per " + columnString; 
		}
		if (! rowString.equals("Empty")) {
			tail = rowString + tail; 
		}
		if (factor.equals(one) && tail == "") {
			return "1";
		} else if (factor.equals(one)) {
			return tail;
		} else if (rowString.equals("Empty")) {
			return factorString + tail;
		} else {
			return factorString + " x " + tail;
		}
	}

	public MatrixType extractColumn() {
		return new MatrixType(factor, rowType, new IndexType());
	}
	
	public MatrixType extractRow() {
		return new MatrixType(factor, new IndexType(), columnType);
	}

	public MatrixType leftIdentity() {
		return new MatrixType(new PowerProduct(), rowType, rowType);
	}

	public MatrixType rightIdentity() {
		return new MatrixType(new PowerProduct(), columnType, columnType);
	}
}
package mvm.values.matrix;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.math.fraction.BigFraction;
import org.apache.commons.math.fraction.BigFractionField;
import org.apache.commons.math.linear.FieldLUDecomposition;
import org.apache.commons.math.linear.FieldLUDecompositionImpl;
import org.apache.commons.math.linear.FieldMatrix;
import org.apache.commons.math.linear.SparseFieldMatrix;

public class MatrixNumbers {
	
	private FieldMatrix<BigFraction> numbers;
	
	public MatrixNumbers(int nrRows, int nrColumns) {
		numbers = new SparseFieldMatrix<BigFraction>(BigFractionField.getInstance(), nrRows, nrColumns);
	}
	
	private MatrixNumbers(FieldMatrix<BigFraction> numbers) {
		this.numbers = numbers;
	}
	
	public int hashCode() {
		return numbers.hashCode();
	}
	
	public boolean equals(Object other) {
		if (other == this) {
			return true;
		}
		if (! (other instanceof MatrixNumbers)) {
			return false;
		}
		MatrixNumbers otherMatrixNumbers = (MatrixNumbers) other;
		if (this.isZero() && otherMatrixNumbers.isZero()) {
			return true;
		} else {
			return this.numbers.equals(otherMatrixNumbers.numbers);
		}
	}

	
	public void set(int i, int j, int num) {
		numbers.setEntry(i, j, new BigFraction(num));
	}

	public void set(int i, int j, double num) {
		numbers.setEntry(i, j, new BigFraction(num));
	}

	public void set(int i, int j, BigFraction num) {
		numbers.setEntry(i, j, num);
	}

//	public void set(int i, int j, BigDecimal num) {
//		numbers.setEntry(i, j, new BigFraction(num));
//	}

	public int nrRows() {
		return numbers.getRowDimension();
	}

	public int nrColumns() {
		return numbers.getColumnDimension();
	}
	
	public static MatrixNumbers identityNumbers(int size) {
		MatrixNumbers numbers = new MatrixNumbers(size,size);
		for (int i=0; i<size; i++) {	
			numbers.set(i, i, BigFraction.ONE);
		}
		return numbers;
	}
	
	public boolean isZero() {
		for (int i=0; i < nrRows(); i++) {
			for (int j=0; j < nrColumns(); j++) {
				if (numbers.getEntry(i, j).compareTo(BigFraction.ZERO) != 0) {
					return false;
				}
			}
		}
		return true;
	}

	public BigFraction get(int row, int column) {
		if (isZero()) {
			return BigFraction.ZERO;
		} else {
			return numbers.getEntry(row, column);
		}
	}

	public MatrixNumbers copy() {
		// TODO Auto-generated method stub
		System.out.println("Copy on MatrixNumbers is not implemented!!!");
		return null;
	}

	public MatrixNumbers getColumn(int column) {
		MatrixNumbers nums = new MatrixNumbers(numbers.getRowDimension(), numbers.getColumnDimension());
		nums.numbers = numbers.getColumnMatrix(column);
		return nums;
	}

	public MatrixNumbers getRow(int row) {
		MatrixNumbers nums = new MatrixNumbers(numbers.getRowDimension(), numbers.getColumnDimension());
		nums.numbers = numbers.getRowMatrix(row);
		return nums;
	}

	public MatrixNumbers transpose() {
		return new MatrixNumbers(numbers.transpose());
	}

	public MatrixNumbers add(MatrixNumbers other) {
		return new MatrixNumbers(numbers.add(other.numbers));
	}

	public MatrixNumbers multiply(MatrixNumbers other) {
		MatrixNumbers nums = new MatrixNumbers(nrRows(), nrColumns());
		for (int i=0; i < nrRows(); i++) {
			for (int j=0; j < nrColumns(); j++) {
				nums.numbers.setEntry(i, j, numbers.getEntry(i, j).multiply(other.numbers.getEntry(i, j)));
			}
		}
		return nums;
	}

	public MatrixNumbers scale(BigFraction factor) {
		return new MatrixNumbers(numbers.scalarMultiply(factor));
	}

	public MatrixNumbers reciprocal() {
		MatrixNumbers nums = new MatrixNumbers(nrRows(), nrColumns());
		BigFraction numerator;
		for (int i=0; i < nrRows(); i++) {
			for (int j=0; j < nrColumns(); j++) {
				numerator = numbers.getEntry(i, j);				
				if (numerator.compareTo(BigFraction.ZERO) != 0) {
					nums.set(i,j, BigFraction.ONE.divide(numerator));
				}	
			}
		}
		return nums;
	}

	public MatrixNumbers join(MatrixNumbers other) {
		return new MatrixNumbers(numbers.multiply(other.numbers));
	}

	public MatrixNumbers closure() {
		MatrixNumbers ident = identityNumbers(nrRows());
		FieldLUDecomposition<BigFraction> decomposition = new FieldLUDecompositionImpl<BigFraction>(ident.numbers.subtract(numbers));
		return new MatrixNumbers(decomposition.getSolver().getInverse().subtract(ident.numbers));
	}

	public MatrixNumbers kleene() {
		MatrixNumbers ident = identityNumbers(nrRows());
		FieldLUDecomposition<BigFraction> decomposition = new FieldLUDecompositionImpl<BigFraction>(ident.numbers.subtract(numbers));
		return new MatrixNumbers(decomposition.getSolver().getInverse());
	}
	
	public MatrixNumbers solve(MatrixNumbers other) {
		FieldLUDecomposition<BigFraction> decomposition = new FieldLUDecompositionImpl<BigFraction>(numbers);
		return new MatrixNumbers(decomposition.getSolver().solve(other.numbers));
	}
	
	public List<MatrixNumbers> plu() {
		FieldLUDecomposition<BigFraction> decomposition = new FieldLUDecompositionImpl<BigFraction>(numbers);
		List<MatrixNumbers> plu = new ArrayList<MatrixNumbers>();
		FieldMatrix<BigFraction> pMatrix = decomposition.getP();
		
		if (pMatrix == null) return plu;
		
		plu.add(new MatrixNumbers(pMatrix));
		plu.add(new MatrixNumbers(decomposition.getL()));
		plu.add(new MatrixNumbers(decomposition.getU()));
		
		return plu;
	}
	
	public BigFraction total() {
		BigFraction sum = BigFraction.ZERO;
		for (int i=0; i < nrRows(); i++) {
			for (int j=0; j < nrColumns(); j++) {
				sum = sum.add(numbers.getEntry(i, j));
			}
		}
		return sum;
	}

	public boolean less(MatrixNumbers other) {

		if (this.isZero() && other.isZero()) {
			return false;
		}
		
		if (this.isZero()) {
			for (int i=0; i < nrRows(); i++) {
				for (int j=0; j < nrColumns(); j++) {
					if (BigFraction.ZERO.compareTo(other.numbers.getEntry(i, j)) >= 0) {
						return false;
					}	
				}
			}
			return true;
		}
		
		if (other.isZero()) {
			for (int i=0; i < nrRows(); i++) {
				for (int j=0; j < nrColumns(); j++) {
					if (numbers.getEntry(i, j).compareTo(BigFraction.ZERO) >= 0) {
						return false;
					}	
				}
			}
			return true;
		}

		for (int i=0; i < nrRows(); i++) {
			for (int j=0; j < nrColumns(); j++) {
				if (numbers.getEntry(i, j).compareTo(other.numbers.getEntry(i, j)) >= 0)  {
					return false;
				}	
			}
		}
		
		return true;
	}
	
	public boolean lessEq(MatrixNumbers other) {

		if (this.isZero() && other.isZero()) {
			return true;
		}
		
		if (this.isZero()) {
			for (int i=0; i < nrRows(); i++) {
				for (int j=0; j < nrColumns(); j++) {
					if (BigFraction.ZERO.compareTo(other.numbers.getEntry(i, j)) > 0) {
						return false;
					}	
				}
			}
			return true;
		}
		
		if (other.isZero()) {
			for (int i=0; i < nrRows(); i++) {
				for (int j=0; j < nrColumns(); j++) {
					if (numbers.getEntry(i, j).compareTo(BigFraction.ZERO) > 0) {
						return false;
					}	
				}
			}
			return true;
		}

		for (int i=0; i < nrRows(); i++) {
			for (int j=0; j < nrColumns(); j++) {
				if (numbers.getEntry(i, j).compareTo(other.numbers.getEntry(i, j)) > 0)  {
					return false;
				}	
			}
		}
		
		return true;
	}

	public MatrixNumbers abs() {
		MatrixNumbers nums = new MatrixNumbers(nrRows(), nrColumns());
		for (int i=0; i < nrRows(); i++) {
			for (int j=0; j < nrColumns(); j++) {
				nums.set(i, j, numbers.getEntry(i, j).abs());
			}
		}
		return nums;
	}

	public MatrixNumbers div(MatrixNumbers other) {
		MatrixNumbers nums = new MatrixNumbers(nrRows(), nrColumns());
		for (int i=0; i < nrRows(); i++) {
			for (int j=0; j < nrColumns(); j++) {
				BigInteger div = numbers.getEntry(i, j).bigDecimalValue().toBigInteger().divide(other.numbers.getEntry(i, j).bigDecimalValue().toBigInteger()); 
				nums.set(i, j, new BigFraction(div));
			}
		}
		return nums;
	}
	
	public MatrixNumbers mod(MatrixNumbers other) {
		MatrixNumbers nums = new MatrixNumbers(nrRows(), nrColumns());
		for (int i=0; i < nrRows(); i++) {
			for (int j=0; j < nrColumns(); j++) {
				BigInteger mod = numbers.getEntry(i, j).bigDecimalValue().toBigInteger().mod(other.numbers.getEntry(i, j).bigDecimalValue().toBigInteger()); 
				nums.set(i, j, new BigFraction(mod));
			}
		}
		return nums;
	}

	public MatrixNumbers support() {
		MatrixNumbers nums = new MatrixNumbers(nrRows(), nrColumns());
		for (int i=0; i < nrRows(); i++) {
			for (int j=0; j < nrColumns(); j++) {
				if (numbers.getEntry(i, j).compareTo(BigFraction.ZERO) != 0) { 
					nums.set(i, j, 1);
				}
			}
		}
		return nums;
	}
}

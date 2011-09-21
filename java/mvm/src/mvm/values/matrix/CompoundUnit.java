package mvm.values.matrix;

import java.util.List;

import units.BaseUnit;
import units.PowerProduct;
import units.Unit;


public class CompoundUnit extends BaseUnit {

	private List<Unit> units;
	
	public CompoundUnit(List<Unit> units) {
		this.units = units;
		setDefinition(this);
	}
	
	public int width() {
		return units.size();
	}
	
	public Unit nthUnit(int n) {
		return units.get(n);
	}
	
	public int hashCode() {
		return units.hashCode();
	}
	
	public boolean equals(Object other) {
		if (other == this) {
			return true;
		}
		if (! (other instanceof Unit)) {
			return false;
		}
		Object real = PowerProduct.normal((Unit)other);
		if (real == this) {
			return true;
		}
		if (! (real instanceof CompoundUnit)) {
			return false;
		}
		CompoundUnit otherUnit = (CompoundUnit) real;
		if (! units.equals(otherUnit.units)) {
			return false;
		}
		return true;
	}
	
	public String pprint() {
		String name = "";
		String sep = "";
		for (Unit unit: units) {
			name = name + sep + unit.pprint();
			sep = ",";
		}
		return name;
	}
}
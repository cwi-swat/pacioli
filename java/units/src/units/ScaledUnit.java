package units;

public class ScaledUnit extends BaseUnit {

	private NamedUnit unit;
	private Prefix prefix;
	
	public ScaledUnit(Prefix scale, NamedUnit scaled){
		prefix = scale;
		unit = scaled;
		setDefinition(unit.multiply(prefix.prefixFactor()));
	}

	public int hashCode() {
		return unit.hashCode();
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
		if (! (real instanceof ScaledUnit)) {
			return false;
		}
		ScaledUnit otherUnit = (ScaledUnit) real;
		if (! unit.equals(otherUnit.unit)) {
			return false;
		}
		if (! prefix.equals(otherUnit.prefix)) {
			return false;
		}
		return true;
	}

	public String pprint() {
		return prefix.prefixName() + unit.pprint();
	}
	
}

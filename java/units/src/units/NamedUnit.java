package units;

public class NamedUnit extends BaseUnit {
	
	private String symbolic;
	
	public NamedUnit(String symbolic){
		this.symbolic = symbolic;
		this.definition = this;
	}
	
	public NamedUnit(String symbolic, Unit definition){
		this.symbolic = symbolic;
		setDefinition(definition);
	}

	public int hashCode() {
		return symbolic.hashCode();
	}
	
	public boolean equals(Object other) {
		if (other == this) {
			return true;
		}
		if (! (other instanceof Unit)) {
			return false;
		}
		Unit real = PowerProduct.normal((Unit)other);
		if (real == this) {
			return true;
		}
		if (! (real instanceof NamedUnit)) {
			return false;
		}
		NamedUnit otherUnit = (NamedUnit) real;
		if (! symbolic.equals(otherUnit.symbolic)) {
			return false;
		}
		return true;
	}

	public String pprint() {
		return symbolic;
	}

}
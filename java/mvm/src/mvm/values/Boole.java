package mvm.values;


public class Boole implements PacioliValue {

	private boolean value;

	public Boole(boolean value) {
		this.value = value;
	}
	
	public boolean positive() {
		return value;
	}
	
	public String pprint() {
		if (value) {
			return "true";
		} else {
			return "false";
		}
	}
	
	public int hashCode() {
		return value ? 0 : 1;
	}
	
	public boolean equals(Object other) {
		if (other == this) {
			return true;
		}
		if (! (other instanceof Boole)) {
			return false;
		}
		Boole otherBoole = (Boole) other;
		return this.value == otherBoole.value;
	}

}

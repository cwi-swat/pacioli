package mvm;

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
}

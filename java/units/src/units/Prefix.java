package units;

public class Prefix {
	
	private String symbols;
	private Number factor;
	
	public Prefix(String symbols, Number factor){
		this.symbols = symbols;
		this.factor = factor;
	}

	public int hashCode() {
		return symbols.hashCode();
	}
	
	public boolean equals(Object other) {
		if (other == this) {
			return true;
		}
		if (! (other instanceof Prefix)) {
			return false;
		}
		Prefix otherPrefix = (Prefix) other;
		if (! symbols.equals(otherPrefix.symbols)) {
			return false;
		}
		return true;
	}

	public String prefixName(){
		return symbols;
	}
	
	public Number prefixFactor(){
		return factor;
	}
}

package units;
import java.util.HashSet;
import java.util.Set;


public abstract class BaseUnit implements Base {

	protected Unit definition;
	
	public void setDefinition(Unit definition){
		this.definition = definition.flat();
	}
	
	public Set<Base> bases() {
		Set<Base> set = new HashSet<Base>();
		set.add(this);
		return set;
	}
	
	public int power(Base base) {
		return 1;
	}
	
	public Number factor() {
		return 1;
	}

	public Unit multiply(Unit other){
		PowerProduct me = new PowerProduct(this); 
		return me.multiply(other);
	}

	public Unit multiply(Number other){
		PowerProduct me = new PowerProduct(this); 
		return me.multiply(other);
	}

	public Unit raise(int power) {
		PowerProduct me = new PowerProduct(this); 
		return me.raise(power);
	}

	public Unit flat() {
		return definition;
	}
}

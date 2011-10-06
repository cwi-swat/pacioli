package units;

import java.util.Set;


public interface Unit {
	
	public Set<Base> bases();
	public int power(Base base);
	public Number factor();
	
	public Unit multiply(Unit other);
	public Unit multiply(Number factor);
	public Unit raise(int power);
	
	public Unit flat();
	public String pprint();
	
	public static final Unit ONE = new PowerProduct(); 
}
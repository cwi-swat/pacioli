package units;

import java.util.HashSet;
import java.util.Set;
import java.util.HashMap;


public class PowerProduct implements Unit {

	private HashMap<Base,Integer> powers;
	private Number factor;
	
	public PowerProduct(){
		powers = new HashMap<Base,Integer>();
		factor = 1;
	}
	
	public PowerProduct(Base base){
		powers = new HashMap<Base,Integer>();
		powers.put(base, 1);
		factor = 1;
	}

	private PowerProduct(HashMap<Base,Integer> map){
		powers = map;
		factor = 1;
	}
	
	public Set<Base> bases() {
		Set<Base> bases = new HashSet<Base>();
		for (Base base: powers.keySet()) {
			if (power(base) != 0) {
				bases.add(base);
			}
		}
		return bases;
	}

	public int power(Base base) {
		Integer value = powers.get(base);
		return (value == null ? 0 : value);
	}
	
	public Number factor() {
		return factor;
	}
	
	public static Unit normal(Unit unit) {
		Set<Base> bases = unit.bases();
		if (unit.factor().doubleValue() == 1 && bases.size() == 1) {
			Base base = (Base) bases.toArray()[0];
			if (unit.power(base) == 1) {
				return base;
			} else {
				return unit;
			}
		} else {
			return unit;
		}
	}
	
	public int hashCode() {
		return powers.hashCode();
	}
	
	public boolean equals(Object other) {
		if (other == this) {
			return true;
		}
		if (! (other instanceof Unit)) {
			return false;
		}
		Unit otherUnit = (Unit) other;
		if (factor.doubleValue() != otherUnit.factor().doubleValue()) {
			return false;
		}
		for (Base base: bases()){
			if (power(base) != otherUnit.power(base)) {
				return false;
			}
		}
		for (Base base: otherUnit.bases()){
			if (power(base) != otherUnit.power(base)) {
				return false;
			}
		}
		return true;
	}
	
	public Unit multiply(Number factor){
		HashMap<Base,Integer> hash = new HashMap<Base,Integer>();
		for (Base base: bases()){
			hash.put(base, power(base));
		}
		PowerProduct scaled = new PowerProduct(hash);
		scaled.factor = this.factor.doubleValue() * factor.doubleValue();
		return scaled;
	}
	
	public Unit multiply(Unit other){
		
		HashMap<Base,Integer> hash = new HashMap<Base,Integer>();
		for (Base base: bases()){
			hash.put(base, power(base));
		}
		for (Base base: other.bases()){
			hash.put(base, other.power(base) + power(base));
		}
		PowerProduct multiplied = new PowerProduct(hash);
		multiplied.factor = other.factor().doubleValue() * factor.doubleValue();
		return multiplied;
	}

	public Unit raise(int power) {
		
		HashMap<Base,Integer> hash = new HashMap<Base,Integer>();
		for (Base base: bases()){
			hash.put(base, power(base) * power);
		}
		PowerProduct raised = new PowerProduct(hash);
		raised.factor = Math.pow(factor.doubleValue(), power);
		return raised;
	}

	public Unit flat() {
		Unit newUnit = new PowerProduct().multiply(factor());
		for (Base base: bases()){
			Unit flattened = base.flat().raise(power(base));
			newUnit = newUnit.multiply(flattened);
		}
		return newUnit;
	}
	
	public String pprint() {
		
		// Geen schoonheidsprijs :)
		String symbolic = factor().toString();
		String sep = "·";
		if (factor().doubleValue() == 1) {
			symbolic = ""; // to avoid the annoying 1.0 of doubles. todo: reconsider numeric type
			sep = "";
		} 
		for (Base base: bases()){
			int power = power(base);
			if (0 < power) {
				symbolic = symbolic.concat(sep);
				sep = "·";
				symbolic = symbolic.concat(base.pprint());

				if (power != 1) {
					symbolic = symbolic.concat("^");
					symbolic = symbolic.concat(Integer.toString(power));
				}
			}
		}
		sep = "/";
		for (Base base: bases()){
			int power = power(base);
			if (power < 0) {
				power = -power;
				symbolic = symbolic.concat(sep);
				sep = "·";
				symbolic = symbolic.concat(base.pprint());

				if (power != 1) {
					symbolic = symbolic.concat("^");
					symbolic = symbolic.concat(Integer.toString(power));
				}
			}
		}
		if (symbolic == "") {
			return "1";
		}
		return symbolic;

	}

}
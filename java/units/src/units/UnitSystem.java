package units;
import java.io.IOException;
import java.util.HashMap;


public class UnitSystem {
	
	private HashMap<String,Unit> unitDictionary;
	private HashMap<String,Prefix> prefixDictionary;
	
	public UnitSystem(){
		unitDictionary = new HashMap<String,Unit>();
		prefixDictionary = new HashMap<String,Prefix>();
	}
	
	public void addUnit(String name, Unit unit){
		unitDictionary.put(name, unit);
	}
	
	public Unit lookupUnit(String name) throws IOException{
		if (unitDictionary.containsKey(name)) {
			return unitDictionary.get(name);
		} else {
			throw new IOException("No unit named " + name);
		}
	}

	public void addPrefix(String name, Prefix prefix){
		prefixDictionary.put(name, prefix);
	}
	
	public Prefix lookupPrefix(String name) throws IOException{
		if (prefixDictionary.containsKey(name)) {
			return prefixDictionary.get(name);
		} else {
			throw new IOException("No prefix named " + name);
		}
	}
}

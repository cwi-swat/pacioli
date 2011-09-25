package mvm.values;

import java.util.List;

import mvm.values.matrix.Index;

public class Key implements PacioliValue {

	public List<String> names;
	//private CompoundEntityType type;
	public Index index;
	
	//public Key(List<String> names, CompoundEntityType type) {
	public Key(List<String> names, Index index) {
		this.names = names;
		this.index = index;
	}
	
	public String pprint() {
		if (names.size() == 0) {
			return "empty";
		}
		String text = "";
		String sep = ""; 
		for (String name: names) {
			text += sep + name;
			sep = "/";
		}
		return text;
	}
	
	public int hashCode() {
		return names.hashCode();
	}
	
	public boolean equals(Object other) {
		if (other == this) {
			return true;
		}
		if (! (other instanceof Key)) {
			return false;
		}
		Key otherKey = (Key) other;
		return this.names.equals(otherKey.names);
	}	
}

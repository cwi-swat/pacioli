package mvm.values;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import mvm.values.matrix.Index;

public class Key implements PacioliValue {

	public List<String> names;
	public Index index;

	public Key() throws IOException {
		this.names = new ArrayList<String>();
		this.index = new Index();
	}

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

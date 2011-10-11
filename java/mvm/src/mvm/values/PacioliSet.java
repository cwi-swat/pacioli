package mvm.values;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;


public class PacioliSet implements PacioliValue {


	private Set<PacioliValue> items;
	
	public PacioliSet() {
		items = new HashSet<PacioliValue>();
	}
	
	public PacioliSet(PacioliValue item) {
		items = new HashSet<PacioliValue>();
		items.add(item);
	}
	
	public PacioliSet union(PacioliSet other) {
		PacioliSet union = new PacioliSet();
		union.items.addAll(items);
		union.items.addAll(other.items);
		return union;
	}

	public int hashCode() {
		return items.hashCode();
	}
	
	public boolean equals(Object other) {
		if (other == this) {
			return true;
		}
		if (! (other instanceof PacioliSet)) {
			return false;
		}
		PacioliSet otherSet = (PacioliSet) other;
		return items.equals(otherSet.items);
	}
	
	public String pprint() {
		String text = "{";
		String sep = "";
		for (PacioliValue value: items) {
			text += sep + value.pprint();
			sep = ", ";
		}
		return text + "}";
	}

	public List<PacioliValue> items() {
		//List<PacioliValue> items = new ArrayList<PacioliValue>(items);
		return new ArrayList<PacioliValue>(items);
	}

	public PacioliValue adjoinMut(PacioliValue y) {
//		if (!items.contains(y)) {
//			items.add(y);
//		}
		items.add(y);
		return this;		
	}
}

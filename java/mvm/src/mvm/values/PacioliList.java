package mvm.values;

import java.util.ArrayList;
import java.util.List;


public class PacioliList implements PacioliValue {

	private final List<PacioliValue> items;

	public PacioliList() {
		items = new ArrayList<PacioliValue>();
	}
	
	public PacioliList(PacioliValue value) {
		items = new ArrayList<PacioliValue>();
		items.add(value);
	}
	
	public PacioliList(List<PacioliValue> values) {
		items = values;
	}
	
//	public PacioliList(PacioliList x, PacioliList y) {
//		items = new ArrayList<PacioliValue>();
//		for (PacioliValue value: x.items) {
//			items.add(value);
//		}
//		for (PacioliValue value: y.items) {
//			items.add(value);
//		}
//	}

	public String pprint() {
		String text = "[";
		String sep = "";
		for (PacioliValue value: items) {
			text += sep + value.pprint();
			sep = ", ";
		}
		return text + "]";
	}

	public List<PacioliValue> items() {
		return items;
	}

	public PacioliValue append(PacioliList y) {
		ArrayList<PacioliValue> accu = new ArrayList<PacioliValue>();
		accu.addAll(items);
		accu.addAll(y.items);
		return new PacioliList(accu);
	}

	public int hashCode() {
		return items.hashCode();
	}
	
	public boolean equals(Object other) {
		if (other == this) {
			return true;
		}
		if (! (other instanceof PacioliList)) {
			return false;
		}
		PacioliList otherList= (PacioliList) other;
		return items.equals(otherList.items);
	}

	public PacioliValue zip(PacioliList other) {
		ArrayList<PacioliValue> accu = new ArrayList<PacioliValue>();
		int size = Math.min(items.size(), other.items.size());
		for (int i=0; i<size; i++) {
			List<PacioliValue> pair = new ArrayList<PacioliValue>();
			pair.add(items.get(i));
			pair.add(other.items.get(i));
			accu.add(new PacioliTuple(pair));
		}
		return new PacioliList(accu);
	}

	public PacioliValue addMut(PacioliValue x) {
		items.add(x);
		return this;
	}
}

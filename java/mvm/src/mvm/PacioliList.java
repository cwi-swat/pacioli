package mvm;

import java.util.ArrayList;
import java.util.List;

public class PacioliList implements PacioliValue {

	private List<PacioliValue> items;

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
	
	public PacioliList(PacioliList x, PacioliList y) {
		items = new ArrayList<PacioliValue>();
		for (PacioliValue value: x.items) {
			items.add(value);
		}
		for (PacioliValue value: y.items) {
			items.add(value);
		}
	}

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
}

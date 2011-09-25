package mvm.values;

import java.util.List;

public class PacioliTuple implements PacioliValue {

	private List<PacioliValue> items;

	public PacioliTuple(List<PacioliValue> items) {
		this.items = items;
	}
	
	public String pprint() {
		String text = "(";
		String sep = "";
		for (PacioliValue value: items) {
			text += sep + value.pprint();
			sep = ", ";
		}
		return text + ")";
	}

	public List<PacioliValue> items() {
		return items;
	}

}

package mvm.primitives;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import mvm.values.Callable;
import mvm.values.PacioliList;
import mvm.values.PacioliValue;

public class SingletonList implements Callable {

	public String pprint() {
		return "singletonList";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'singletonList' expects one argument");
		}
		PacioliValue x = params.get(0);
		List<PacioliValue> list = new ArrayList<PacioliValue>();
		list.add(x);
		return new PacioliList(list);
	}

}

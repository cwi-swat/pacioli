package mvm.primitives;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import mvm.Callable;
import mvm.PacioliList;
import mvm.PacioliValue;

public class Single implements Callable {

	public String pprint() {
		return "single";
	}

	public PacioliValue apply(List<PacioliValue> params) throws IOException {
		if (params.size() != 1) {
			throw new IOException("function 'single' expects one argument");
		}
		PacioliValue x = params.get(0);
		List<PacioliValue> list = new ArrayList<PacioliValue>();
		list.add(x);
		return new PacioliList(list);
	}

}

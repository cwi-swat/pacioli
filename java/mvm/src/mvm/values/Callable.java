package mvm.values;

import java.io.IOException;
import java.util.List;


public interface Callable extends PacioliValue {
	public PacioliValue apply(List<PacioliValue> params) throws IOException;
}

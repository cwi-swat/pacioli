package mvm;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import mvm.values.PacioliList;
import mvm.values.PacioliSet;
import mvm.values.PacioliValue;

public class Environment {
	
	private HashMap<String, PacioliValue> store;

	public Environment() {
		store = new HashMap<String, PacioliValue>();
	}
	
	public Environment(String key, PacioliValue value) {
		store = new HashMap<String, PacioliValue>();
		store.put(key, value);
	}
	
	public Environment(List<String> arguments, Environment env) {
		store = new HashMap<String, PacioliValue>();
		for (int i=0; i < arguments.size(); i++) {
			store.put(arguments.get(i), env.store.get(i));
		}
	}

	public Environment(List<String> arguments, List<PacioliValue> params) {
		store = new HashMap<String, PacioliValue>();
		for (int i=0; i < arguments.size(); i++) {
			store.put(arguments.get(i), params.get(i));
		}
	}

	public Environment extend(Environment other) {
		Environment copy = this.clone();
		for (String key: other.store.keySet()) {
			copy.store.put(key, other.store.get(key));
		}
		return copy;
	}
	
	@SuppressWarnings("unchecked")
	public Environment clone() {
		Environment env = new Environment();
		env.store = (HashMap<String, PacioliValue>) store.clone();
		return env;
	}

	public PacioliValue lookup(String name) throws IOException {
		
		if (name.equals("emptyList")) {
			return new PacioliList(new ArrayList<PacioliValue>());
		}
		
		if (name.equals("emptySet")) {
			return new PacioliSet();
		}
		
		if (store.containsKey(name)) {
			return store.get(name);
		} else {
			throw new IOException(String.format("variable '%s' unknown", name));
		}
			
	}
}

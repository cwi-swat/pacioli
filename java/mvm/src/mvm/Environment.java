package mvm;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import mvm.values.Key;
import mvm.values.PacioliList;
import mvm.values.PacioliSet;
import mvm.values.PacioliValue;

public class Environment {
	
	private HashMap<String, PacioliValue> store;
	private Environment next;

	public Environment() {
		store = new HashMap<String, PacioliValue>();
		next = null;
	}
	
	public Environment(String key, PacioliValue value) {
		store = new HashMap<String, PacioliValue>();
		store.put(key, value);
		next = null;
	}
	
	public Environment(List<String> arguments, Environment env) {
		store = new HashMap<String, PacioliValue>();
		for (int i=0; i < arguments.size(); i++) {
			store.put(arguments.get(i), env.store.get(i));
		}
		next = null;
	}

	public Environment(List<String> arguments, List<PacioliValue> params) {
		store = new HashMap<String, PacioliValue>();
		for (int i=0; i < arguments.size(); i++) {
			store.put(arguments.get(i), params.get(i));
		}
		next = null;
	}
	public PacioliValue lookup(String name) throws IOException {
		
		if (name.equals("emptyList")) {
			return new PacioliList(new ArrayList<PacioliValue>());
		}
		
		if (name.equals("emptySet")) {
			return new PacioliSet();
		}
		
		if (name.equals("empty")) {
			return new Key();
		}
		
		if (store.containsKey(name)) {
			return store.get(name);
		} else {
			if (next == null) {
				throw new IOException(String.format("variable '%s' unknown", name));
			} else {
				return next.lookup(name);
			}
		}
			
	}

	public Environment pushUnto(Environment environment) {
		if (next == null) {
			next = environment;
			return this;
		} else {
			throw new RuntimeException("huh");
		}
	}

	public boolean containsKey(String name) {
		if (store.containsKey(name)) {
			return true;
		}
		if (next != null) {
			return next.containsKey(name);
		}
		return false;
	}

	public Set<Map.Entry<String, PacioliValue>> entrySet() {
		Set<Map.Entry<String, PacioliValue>> keys = store.entrySet();
		if (next != null) {
			keys.addAll(next.entrySet());
		}
		return keys;
	}

	public void put(String name, PacioliValue value) {
		store.put(name, value);
	}

	public Set<String> keySet() {
		Set<String> keys = store.keySet();
		if (next != null) {
			keys.addAll(next.keySet());
		}
		return keys;
	}
}

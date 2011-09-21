package mvm.values.matrix;

import java.util.HashMap;
import java.util.List;


public class Entity {

	private HashMap<String, Integer> positions;
	private String[] elements;

	public Entity(List<String> elements) {
		
		int len = elements.size();
		
		this.elements = new String[len];
		this.positions = new HashMap<String, Integer>();
		
		int i = 0;
		for (String name: elements) {
			this.elements[i] = name;
			positions.put(name,i);
			i++;
		}
	}
	
	public int size() {
		return elements.length;
	}
	
	public String ElementAt(int index) {
		return elements[index];
	}
	
	public int ElementPosition(String element) {
		return positions.get(element);
	}
}
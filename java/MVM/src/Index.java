import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import units.Base;
import units.Unit;
import units.PowerProduct;

public class Index {

	private IndexType type;
	private List<Entity> entities;
	private List<Unit[]> units;
	private Map<List<String>, Integer> positions;
	
	private Index(IndexType type, List<Entity> entities, List<Unit[]> units, Map<List<String>, Integer> positions) {
		this.type = type;
		this.entities = entities;
		this.units = units;
		this.positions = positions;
	}
			
	public Index(IndexType type, Map<String, Entity> entityCallback, Map<Base, Unit[]> unitCallback) throws IOException {
		this.type = type;
		entities = entityList(entityCallback);
		positions = positionsMap();
		units = unitArrayList(unitCallback);
	}

	private List<Entity> entityList(Map<String, Entity> callback) throws IOException {
		ArrayList<Entity> entities = new ArrayList<Entity>();
		for (int i=0; i<type.width(); i++) {
		//for (EntityType entityType: type.entityTypeList())
			EntityType entityType = type.nthEntityType(i);
			String name = ((SimpleEntityType) entityType).getName();
			if (callback.containsKey(name)) {
				entities.add(callback.get(name)); 
			} else
			{
				throw new IOException(String.format("Entity '%s' not found", name));
			}
		}
		return entities;
	}
	
	private Map<List<String>, Integer> positionsMap() {
		Map<List<String>, Integer> positions = new HashMap<List<String>, Integer>();
		for (int i=0; i<size(); i++) {
			positions.put(ElementAt(i), i);
		}
		return positions;
	}
	
	private List<Unit[]> unitArrayList(Map<Base, Unit[]> callback) throws IOException {
		
		List<Unit[]> unitArrays = new ArrayList<Unit[]>();
		
		//List<Unit> unitList = type.unitList();
		Unit one = new PowerProduct();
		
		for (int i=0; i<width(); i++) {
			
			Entity entity = entities.get(i);
			Unit unit = type.nthUnit(i); //unitList.get(i);
			
			Unit[] array = new Unit[entity.size()];
			for (int k=0; k<entity.size(); k++) {
				array[k] = one;
			}
			
			for (Base base: unit.bases()) {
				if (callback.containsKey(base)) {
					Unit[] local = callback.get(base);
					int power = unit.power(base);
					for (int l=0; l<entity.size(); l++) {
						array[l] = array[l].multiply(local[l].raise(power).multiply(unit.factor()));
					}		
				} else {
					throw new IOException(String.format("Base unit vector '%s' unknown in %s",
							base.pprint(), unit.pprint()));
				}
			}		
			
			unitArrays.add(array);
		}
		return unitArrays;
	}

	public int size() {
		int size = 1;
		for (Entity entity: this.entities) {
			size = size * entity.size();
		}
		return size;
	}
	
	public int width () {
		return type.width();
	}
	
	public List<String> ElementAt(int index) {
		ArrayList<String> list = new ArrayList<String>();
		int a = index;
		for (Entity entity: entities) {
			list.add(entity.ElementAt(a % entity.size()));
			a = a / entity.size();
		}
		return list;
	}
	
	public int ElementPos(List<String> index) throws IOException {
		if (positions.containsKey(index)) {
			return positions.get(index);	
		} else {
			throw new IOException(String.format("Element '%s' unknown", index));
		}
	}
	
	public Unit unitAt(int index) {
		Unit unit = new PowerProduct();
		int a = index;
		for (Unit[] array: units) {
			unit = unit.multiply(array[a % array.length]);
			a = a / array.length;
		}
		return unit;
	}

	public Index reciprocal() {
		List<Unit[]> newList = new ArrayList<Unit[]>();
		for (Unit[] array: units) {
			Unit[] newUnits = new Unit[array.length];
			for (int i=0; i< array.length; i++) {
				newUnits[i] = array[i].raise(-1);
			}
			newList.add(newUnits);
		}
		return new Index(type.reciprocal(), entities, newList, positions);
	}

	public Index multiply(Index other) throws IOException {
		List<Unit[]> newList = new ArrayList<Unit[]>();
		int k=0;
		for (Unit[] array: units) {
			Unit[] otherArray = other.units.get(k);
			Unit[] newUnits = new Unit[array.length];
			for (int i=0; i< array.length; i++) {
				newUnits[i] = array[i].multiply(otherArray[i]);
			}
			newList.add(newUnits);
			k++;
		}
		return new Index(type.multiply(other.type), entities, newList, positions);
	}
}

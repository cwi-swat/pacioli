package mvm.values.matrix;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;


import units.Base;
import units.PowerProduct;
import units.Unit;

public class IndexType {
	
	private CompoundEntityType entity;
	private Unit unit;
	
	public IndexType() { 
		entity = new CompoundEntityType(new ArrayList<EntityType>());
		unit = new PowerProduct();
	}
	
	private IndexType(CompoundEntityType entity, Unit unit){
		this.entity = entity;
		this.unit = unit;
	}
	
	public IndexType(List<EntityType> entities, List<Unit> units) {
		entity = new CompoundEntityType(entities);
		Unit one = new PowerProduct();
		boolean allOne = true;
		for (Unit item: units) {
			allOne = allOne && item.equals(one);
		}
		unit = allOne ? one : new CompoundUnit(units);
	}

	public IndexType(List<EntityType> entities) {
		entity = new CompoundEntityType(entities);
		unit = new PowerProduct();
	}

	public int hashCode() {
		return entity.hashCode();
	}
	
	public boolean equals(Object other) {
		if (other == this) {
			return true;
		}
		if (! (other instanceof IndexType)) {
			return false;
		}
		IndexType otherType = (IndexType) other;
		if (! entity.equals(otherType.entity)) {
			return false;
		}
		if (! unit.equals(otherType.unit)) {
			return false;
		}
		return true;
	}

	public int width() {
		return entity.width();
	}
	
	public EntityType nthEntityType(int n) {
		assert (n < width());
		return entity.nthEntityType(n);
	}
	
	public Unit nthUnit(int n) {
		assert (n < width());
		Set<Base> bases = unit.bases();
		Unit newUnit = new PowerProduct();
		Unit tmp;
		for (Base base:bases) {
			if (base instanceof CompoundUnit) {
				tmp = ((CompoundUnit) base).nthUnit(n);
			} else {
				tmp = base;
			}
			newUnit = newUnit.multiply(tmp.raise(unit.power(base)));
		}
		return newUnit;
	}
	
	public boolean multiplyable(IndexType other) {
		return entity.equals(other.entity);
	}

	public IndexType multiply(IndexType other){
		return new IndexType(entity, unit.multiply(other.unit));
	}

	public IndexType reciprocal() {
		return new IndexType(entity, unit.raise(-1));
	}
	
	public String pprint() {
		if (width() == 0) {
			return "empty";
		} else {
			String output = "";
			String sep = "";
			Unit one = new PowerProduct();
			Unit unit;
			EntityType type;
			for (int i=0; i<width(); i++) {
				unit = nthUnit(i);
				type = nthEntityType(i);
				if (unit.equals(one)) {
					output += sep + type.pprint();
				} else {
					output += sep + type.pprint() + "." + unit.pprint();
				}
				sep = " * ";
			}
			return output;
		}
	}
}
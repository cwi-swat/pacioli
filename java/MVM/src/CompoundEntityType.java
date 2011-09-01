import java.util.List;


public class CompoundEntityType implements EntityType {

	private List<EntityType> types;
	
	public CompoundEntityType(List<EntityType> types){
		this.types = types;
	}
	
	public int hashCode() {
		return types.hashCode();
	}
	
	public boolean equals(Object other) {
		if (other == this) {
			return true;
		}
		if (! (other instanceof CompoundEntityType)) {
			return false;
		}
		CompoundEntityType otherEntity = (CompoundEntityType) other;
		if (! types.equals(otherEntity.types)) {
			return false;
		}
		return true;
	}
	
	public String pprint(){
		String name = "";
		String sep = "";
		for (EntityType type: types) {
			name = name + sep + type.pprint();
			sep = ",";
		}
		return name;
	}

	public int width() {
		return types.size();
	}
	
	public EntityType nthEntityType(int n) {
		return types.get(n);
	}
}

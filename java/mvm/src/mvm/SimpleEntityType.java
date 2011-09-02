package mvm;


public class SimpleEntityType implements EntityType {
	
	private String name;

	public SimpleEntityType(String name){
		this.name = name;
	}
	
	public String getName() {
		return name;
	}

	public int width() {
		return 1;
	}

	public int hashCode() {
		return name.hashCode();
	}
	
	public boolean equals(Object other) {
		if (other == this) {
			return true;
		}
		if (! (other instanceof SimpleEntityType)) {
			return false;
		}
		SimpleEntityType otherEntity = (SimpleEntityType) other;
		if (! name.equals(otherEntity.name)) {
			return false;
		}
		return true;
	}
	
	public String pprint(){
		return name;
	}	
}
package mvm;

import java.io.EOFException;
import java.io.IOException;
import java.io.Reader;
import java.io.StreamTokenizer;
import java.util.ArrayList;
import java.util.List;

import units.NamedUnit;
import units.PowerProduct;
import units.Prefix;
import units.ScaledUnit;
import units.Unit;
import units.UnitSystem;


public class Tokenizer {
	
	StreamTokenizer tokenizer;
	UnitSystem unitSystem;
	
	public static final int TT_EOF = StreamTokenizer.TT_EOF;
	public static final int TT_WORD = StreamTokenizer.TT_WORD;
	public static final int TT_NUMBER = StreamTokenizer.TT_NUMBER;
	
	public Tokenizer(Reader reader, UnitSystem system) {
		
		tokenizer = new StreamTokenizer(reader);
		unitSystem = system;
		
		tokenizer.wordChars('_', '_');
		tokenizer.ordinaryChar('/');   
		tokenizer.commentChar('-');
		tokenizer.ordinaryChar('.');
		
	}
	
	public String readIdentifier() throws IOException {
		switch (tokenizer.nextToken()) {
		case StreamTokenizer.TT_WORD: 
			return tokenizer.sval;
		case StreamTokenizer.TT_NUMBER: 
			throw new EOFException("expected identifier but found number");
		default:
			throw new EOFException(String.format("expected identifier but found '%s'", (char) tokenizer.ttype));
		}	
	}
	
	public Number readNumber() throws IOException {
		switch (tokenizer.nextToken()) {
		case StreamTokenizer.TT_NUMBER: 
			return tokenizer.nval;
		case StreamTokenizer.TT_WORD: 
			throw new EOFException("expected number but found identifier");
		default:
			throw new EOFException(String.format("expected number but found '%s'", (char) tokenizer.ttype));
		}
	}

	public String readString() throws IOException {
		switch (tokenizer.nextToken()) {
		case '\"': 
			return tokenizer.sval;
		case StreamTokenizer.TT_NUMBER: 
			throw new EOFException("expected string but found number");
		case StreamTokenizer.TT_WORD: 
			throw new EOFException("expected string but found identifier");
		default:
			throw new EOFException(String.format("expected string but found '%s'", (char) tokenizer.ttype));
		}
	}
	
	public void readSeparator() throws IOException {
		switch (tokenizer.nextToken()) {
		case ';': 
			return;
		case StreamTokenizer.TT_EOF: 
			return;
		case StreamTokenizer.TT_NUMBER: 
			throw new EOFException("expected ';' but found number");
		case StreamTokenizer.TT_WORD: 
			throw new EOFException("expected ';' but found identifier");
		default:
			throw new EOFException(String.format("expected ';' but found '%s'", (char) tokenizer.ttype));
		}
	}
		
	public IndexType readIndexType() throws IOException{
		List<String> identifiers = readIdentifierList();
		switch (tokenizer.nextToken()) {
		case StreamTokenizer.TT_EOF:
			if (identifiers.size() == 1 && identifiers.get(0).equals("empty")) {
				return new IndexType();
			} else {
				throw new EOFException("unexpected end of input while reading index type");
			}
		case '.': 
			List<Unit> units = readUnitList(identifiers);
			List<EntityType> entities = new ArrayList<EntityType>();
			for (String identifier: identifiers) {
				entities.add(new SimpleEntityType(identifier));
			}
			if (units.size() == entities.size()) {
				return new IndexType(entities, units);
			} else if (units.size() == 1) {
				if (units.get(0).equals(new PowerProduct())) {
					return new IndexType(entities);
				} else {
					throw new IOException("number of entities and units not equal");
				}
			} else {
				throw new IOException("number of entities and units not equal");
			}			
		case StreamTokenizer.TT_NUMBER: 
			throw new IOException("expected '.' but found number");
		case StreamTokenizer.TT_WORD: 
			throw new IOException("expected '.' but found identifier");
		default:
			throw new IOException(String.format("expected '.' but found '%s'", (char) tokenizer.ttype));
		}
	}
	
	public List<String> readIdentifierList() throws IOException{
		List<String> identifiers = new ArrayList<String>();
		identifiers.add(readIdentifier());
		while (tokenizer.nextToken() == ',') {
			identifiers.add(readIdentifier());
		}
		tokenizer.pushBack();
		return identifiers;
	}

	public List<Unit> readUnitList(List<String> entities) throws IOException{
		List<Unit> units= new ArrayList<Unit>();
		int size = entities.size();
		int i = 0;
		if (i >= size) {
			throw new IOException("to few entities for the units");
		}
		units.add(readUnit(entities.get(i) + "."));
		while (tokenizer.nextToken() == ',') {
			i++;
			if (i >= size) {
				throw new IOException("to few entities for the units");
			}	
			units.add(readUnit(entities.get(i) + "."));
		}
		tokenizer.pushBack();
		return units;
	}

	public Unit readUnit(String entity) throws IOException{
		Unit first = readOneUnit(entity);
		switch (tokenizer.nextToken()) {
		case '*':
			return first.multiply(readOneUnit(entity));
		case '/':
			return first.multiply(readOneUnit(entity).raise(-1));
		case '^':
			return first.raise(readNumber().intValue());
		default:
			tokenizer.pushBack();
			return first;
		}
	}

	public Unit readOneUnit(String entity) throws IOException{
		int token = tokenizer.nextToken();
		int subtoken;
		switch (token) {
		case StreamTokenizer.TT_EOF:
			throw new IOException("unexpected end of input while reading unit");
		case StreamTokenizer.TT_NUMBER:
			return new PowerProduct().multiply(tokenizer.nval);
		case StreamTokenizer.TT_WORD:
			String identifier = tokenizer.sval;
			subtoken = tokenizer.nextToken();
			if (subtoken == StreamTokenizer.TT_WORD) {
				String other = tokenizer.sval;
				Prefix prefix = unitSystem.lookupPrefix(identifier);
				NamedUnit unit = (NamedUnit) unitSystem.lookupUnit(entity+other); // cast in lookupUnit?
				return new ScaledUnit(prefix, unit);
			} else {
				tokenizer.pushBack();
				return unitSystem.lookupUnit(entity+identifier);
			}
		case '(':
			Unit unit = readUnit(entity);
			subtoken = tokenizer.nextToken();
			if (subtoken == ')') {
				return unit;
			} else {
				throw new IOException(String.format("expected closing parenthesis but found '%s'", (char) subtoken));
			}
		default:
			throw new IOException(String.format("expected unit but found '%s'", (char) token));
		}
	}


	public int nextToken() throws IOException {
		return tokenizer.nextToken();
	}


	public String sval() {
		return tokenizer.sval;
	}


	public Object lineno() {
		return tokenizer.lineno();
	}


	public void pushBack() {
		tokenizer.pushBack();
	}
}
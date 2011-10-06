package mvm;

import java.io.EOFException;
import java.io.IOException;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.math.fraction.BigFraction;

import mvm.values.matrix.EntityType;
import mvm.values.matrix.IndexType;
import mvm.values.matrix.SimpleEntityType;
import units.NamedUnit;
import units.PowerProduct;
import units.Prefix;
import units.ScaledUnit;
import units.Unit;
import units.UnitSystem;

public class Reader {

	Tokenizer tokenizer;
	UnitSystem unitSystem;
	
	public Reader(java.io.Reader reader, UnitSystem system) {
		tokenizer = new Tokenizer(reader);
		unitSystem = system;
	}
	
	public boolean hasIdentifier() throws IOException {
		int token = tokenizer.nextToken();
		tokenizer.pushBack();
		return (token == Tokenizer.TT_WORD && !isNumeric((char) token));
	}
	
	public String readIdentifier() throws IOException { 
		if (tokenizer.nextToken() == Tokenizer.TT_WORD) {
			String identifier = tokenizer.sval();
			int token = tokenizer.nextToken();
			while ('0' <= (char) token && (char) token <= '9') {
				identifier += (char) token;
				token = tokenizer.nextToken();
				if (token == Tokenizer.TT_WORD) {
					identifier += tokenizer.sval();
					token = tokenizer.nextToken();
				}
			}
			tokenizer.pushBack();
			return identifier;
		} else {
			throw new EOFException(String.format("expected identifier but found '%s'", (char) tokenizer.ttype));
		}	
	}
	
	public boolean hasNumber() throws IOException {
		int token = tokenizer.nextToken();
		tokenizer.pushBack();
		return isNumeric((char) token);
	}
	
	private boolean isNumeric(char ch) {
		return ('0' <= ch && ch <= '9') || (ch == '-');
	}
	
	public BigFraction readNumber() throws IOException {
		if (hasNumber()) {
			String num = "";
			int token = tokenizer.nextToken();
			while (isNumeric((char) token)) {
				num += (char) token;
				token = tokenizer.nextToken();
			}
			if ((char) token == '.') {
				String denom = "";
				token = tokenizer.nextToken();
				while (isNumeric((char) token)) {
					denom += (char) token;
					token = tokenizer.nextToken();
				}
				tokenizer.pushBack();
				return new BigFraction(new BigInteger(num + denom), new BigInteger("10").pow(denom.length()));
			}
			tokenizer.pushBack();
			return new BigFraction(new BigInteger(num));
		} else {
			throw new EOFException(String.format("expected number but found '%s'", (char) tokenizer.ttype));
		}
	}
	
	public boolean hasString() throws IOException {
		int token = tokenizer.nextToken();
		tokenizer.pushBack();
		return (token == '\"');
	}
	
	public String readString() throws IOException {
		if (tokenizer.nextToken() == '\"') { 
			return tokenizer.sval();
		} else {
			throw new EOFException(String.format("expected string but found '%s'", (char) tokenizer.ttype));
		}
	}

	public boolean hasCharacter(char character) throws IOException {
		int token = tokenizer.nextToken();
		tokenizer.pushBack();
		return (token == character);
	}
	
	public void readCharacter(char character) throws IOException {
		int token = tokenizer.nextToken();
		if (token == character) {
			return;
		} else {
			switch (token) {
			case Tokenizer.TT_EOF: 
				return; // to allow omission of last ;
			case Tokenizer.TT_NUMBER: 
				throw new EOFException(String.format("expected '%s' but found number1", character));
			case Tokenizer.TT_WORD: 
				throw new EOFException(String.format("expected '%s' but found identifier", character));
			default:
				throw new EOFException(String.format("expected '%s' but found '%s'", character, (char) tokenizer.ttype));
			}
		}
	}
	
	public void readSeparator() throws IOException {
		readCharacter(';');
	}
		
	public IndexType readIndexType() throws IOException{
		List<String> identifiers = readIdentifierList();
		switch (tokenizer.nextToken()) {
		case Tokenizer.TT_EOF:
			if (identifiers.size() == 1 && identifiers.get(0).equals("Empty")) {
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
		case Tokenizer.TT_NUMBER: 
			throw new IOException("expected '.' but found number2");
		case Tokenizer.TT_WORD: 
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
		if (hasCharacter('*')) {
			readCharacter('*');
			return first.multiply(readOneUnit(entity));
		} else if (hasCharacter('/')) {
			readCharacter('/');
			return first.multiply(readOneUnit(entity).raise(-1));
		} else if (hasCharacter('^')) {
			readCharacter('^');
			return first.raise(readNumber().intValue());
		} else {
			return first;
		}
	}

	public Unit readOneUnit(String entity) throws IOException{
		if (eof()) {
			throw new IOException("unexpected end of input while reading unit");
		} else if (hasCharacter('(')) {
			readCharacter('(');
			Unit unit = readUnit(entity);
			if (hasCharacter(')')) {
				readCharacter(')');
				return unit;
			} else {
				throw new IOException(String.format("expected closing parenthesis but found '%s'", (char) tokenizer.ttype));
			}
		} else if (hasNumber()) {
			return new PowerProduct().multiply(readNumber());
		} else if (hasIdentifier()) {
			tokenizer.pushBack();
			String identifier = readIdentifier();
			if (hasIdentifier()) {
				String other = readIdentifier();
				Prefix prefix = unitSystem.lookupPrefix(identifier);
				NamedUnit unit = (NamedUnit) unitSystem.lookupUnit(entity+other); // cast in lookupUnit?
				return new ScaledUnit(prefix, unit);
			} else {
				tokenizer.pushBack();
				return unitSystem.lookupUnit(entity+identifier);
			}
		} else {
			throw new IOException(String.format("expected unit but found '%s'", (char) tokenizer.ttype));
		}
	}

	public boolean eof() throws IOException {
		int token = tokenizer.nextToken();
		tokenizer.pushBack();
		return (token == Tokenizer.TT_EOF);
	}

	public char nextChar() throws IOException {
		return (char) tokenizer.nextToken();
	}
	
	public int lineno() {
		return tokenizer.lineno();
	}
}

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

	java.io.Reader reader;
	UnitSystem unitSystem;
	int buffer;
	boolean bufferActive;
	int lineNumber;
	
	public Reader(java.io.Reader reader, UnitSystem system) {
		unitSystem = system;
		this.reader = reader;
		bufferActive = false;
		lineNumber = 1;
	}
	
	private int nextInt() throws IOException {
		if (bufferActive) {
			bufferActive = false;
		} else {
			int next = reader.read();
			buffer = next;
			if ((char) buffer == '\n') {
				lineNumber += 1;
			}
		}
		return buffer;
	}
	
	char nextChar() throws IOException {
		return (char) nextInt();
	}
	
	private void pushBack() {
		bufferActive = true;
	}
	
	public void skipWhitespace() throws IOException {
		if (!eof()) {
			char next = nextChar();
			while (Character.isWhitespace(next)) {
				next = nextChar();
			}
			pushBack();
		}
	}
	
	public boolean hasIdentifier() throws IOException {
		char next = nextChar();
		pushBack();
		return Character.isLetter(next) || next == '_';
	}
	
	public String readIdentifier() throws IOException { 
		skipWhitespace();
		if (hasIdentifier()) {
			String identifier = "";
			char next = nextChar();
			while (Character.isLetterOrDigit(next) || next == '_') {
				identifier += next;
				next = nextChar();
			}
			pushBack();
			return identifier;
		} else {
			throw new EOFException(String.format("expected identifier but found '%s'", nextChar()));
		}	
	}
	
	public boolean hasNumber() throws IOException {
		char next = nextChar();
		pushBack();
		return Character.isDigit(next) || next == '-';
	}
	
	public BigFraction readNumber() throws IOException {
		skipWhitespace();
		if (hasNumber()) {
			String num = "";
			num += nextChar();
			char next = nextChar();
			while (Character.isDigit(next)) {
				num += next;
				next = nextChar();
			}
			if (next == '.') {
				String denom = "";
				next = nextChar();
				while (Character.isDigit(next)) {
					denom += next;
					next = nextChar();
				}
				pushBack();
				return new BigFraction(new BigInteger(num + denom), new BigInteger("10").pow(denom.length()));
			}
			pushBack();
			return new BigFraction(new BigInteger(num));
		} else {
			throw new EOFException(String.format("expected number but found '%s'", nextChar()));
		}
	}
	
	public boolean hasString() throws IOException {
		char next = nextChar();
		pushBack();
		return Character.isDigit(next) || next == '"';
	}
	
	public String readString() throws IOException {
		skipWhitespace();
		char first = nextChar(); 
		if (first == '"') {
			String string = "";
			char next = nextChar();
			if (next == '\\') {
				string += nextChar();
				next = nextChar();
			}	
			while (next != '"') {
				string += next;
				next = nextChar();
				if (next == '\\') {
					string += nextChar();
					next = nextChar();
				}
			}
			return string;
		} else {
			throw new EOFException(String.format("expected string but found '%c'", first));
		}
	}

	public boolean hasCharacter(char character) throws IOException {
		char next = nextChar();
		pushBack();
		return next == character;
	}
		
	public void readCharacter(char character) throws IOException {
		skipWhitespace();
		char next = nextChar();
		if (next == character) {
			return;
		} else {
			throw new EOFException(String.format("expected '%s' but found '%s'", character, next));
		}
	}
	
	public void readSeparator() throws IOException {
		skipWhitespace();
		if (!eof()) {
			readCharacter(';');
		}
	}
		
	public IndexType readIndexType() throws IOException{
		List<String> identifiers = readIdentifierList();
		char next = nextChar();
		if (eof()) {
			if (identifiers.size() == 1 && identifiers.get(0).equals("Empty")) {
				return new IndexType();
			} else {
				throw new EOFException("unexpected end of input while reading index type");
			}
		} else if (next == '.') {
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
		} else {
			throw new IOException(String.format("expected '.' but found '%s'", next));
		}
	}
	
	public List<String> readIdentifierList() throws IOException{
		List<String> identifiers = new ArrayList<String>();
		identifiers.add(readIdentifier());
		while (nextChar() == ',') {
			identifiers.add(readIdentifier());
		}
		pushBack();
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
		while (nextChar() == ',') {
			i++;
			if (i >= size) {
				throw new IOException("to few entities for the units");
			}	
			units.add(readUnit(entities.get(i) + "."));
		}
		pushBack();
		return units;
	}

	public Unit readUnit(String entity) throws IOException{
		Unit first = readOneUnit(entity);
		skipWhitespace();
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
		skipWhitespace();
		if (eof()) {
			throw new IOException("unexpected end of input while reading unit");
		} else if (hasCharacter('(')) {
			readCharacter('(');
			Unit unit = readUnit(entity);
			skipWhitespace();
			if (hasCharacter(')')) {
				readCharacter(')');
				return unit;
			} else {
				throw new IOException(String.format("expected closing parenthesis but found '%s'", nextChar()));
			}
		} else if (hasNumber()) {
			return new PowerProduct().multiply(readNumber());
		} else if (hasIdentifier()) {
			String identifier = readIdentifier();
			skipWhitespace();
			if (hasIdentifier()) {
				String other = readIdentifier();
				Prefix prefix = unitSystem.lookupPrefix(identifier);
				NamedUnit unit = (NamedUnit) unitSystem.lookupUnit(entity+other); // cast in lookupUnit?
				return new ScaledUnit(prefix, unit);
			} else {
				return unitSystem.lookupUnit(entity+identifier);
			}
		} else {
			throw new IOException(String.format("expected unit but found '%s'", nextChar()));
		}
	}

	public boolean eof() throws IOException {
		int next = nextInt();
		pushBack();
		return (next < 0);
	}

	public int lineno() {
		return lineNumber;
	}

	public String nextChars() throws IOException {
		int i = 0;
		String next = "";
		while (!eof() && i <= 5) {
			i++;
			if (hasNumber()) {
				next += readNumber();
			} else if (hasString()) {
				next += "\"" + readString() + "\"";
			} else if (hasIdentifier()) {
				next += readIdentifier();
			} else {
				next += nextChar();
			}
		}
		return next;
	}
}

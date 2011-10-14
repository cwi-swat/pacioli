package mvm;

import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintStream;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import mvm.expressions.And;
import mvm.expressions.Application;
import mvm.expressions.Bang;
import mvm.expressions.Branch;
import mvm.expressions.Const;
import mvm.expressions.Expression;
import mvm.expressions.Lambda;
import mvm.expressions.Or;
import mvm.expressions.Variable;
import mvm.primitives.Abs;
import mvm.primitives.AddMut;
import mvm.primitives.AdjoinMut;
import mvm.primitives.Append;
import mvm.primitives.Apply;
import mvm.primitives.Column;
import mvm.primitives.ColumnDomain;
import mvm.primitives.ColumnIndex;
import mvm.primitives.Div;
import mvm.primitives.Equal;
import mvm.primitives.Gcd;
import mvm.primitives.Get;
import mvm.primitives.Head;
import mvm.primitives.Identity;
import mvm.primitives.IndexLess;
import mvm.primitives.Isolate;
import mvm.primitives.Join;
import mvm.primitives.Kleene;
import mvm.primitives.Less;
import mvm.primitives.LessEq;
import mvm.primitives.LoopList;
import mvm.primitives.LoopMatrix;
import mvm.primitives.Magnitude;
import mvm.primitives.MatrixFromTuples;
import mvm.primitives.Mod;
import mvm.primitives.Multiply;
import mvm.primitives.Negative;
import mvm.primitives.Not;
import mvm.primitives.PosSeries;
import mvm.primitives.Print;
import mvm.primitives.Put;
import mvm.primitives.Reciprocal;
import mvm.primitives.Reduce;
import mvm.primitives.ReduceList;
import mvm.primitives.ReduceMatrix;
import mvm.primitives.ReduceSet;
import mvm.primitives.Row;
import mvm.primitives.RowDomain;
import mvm.primitives.RowIndex;
import mvm.primitives.Scale;
import mvm.primitives.Set;
import mvm.primitives.SingletonList;
import mvm.primitives.SingletonSet;
import mvm.primitives.Size;
import mvm.primitives.Sum;
import mvm.primitives.Tail;
import mvm.primitives.Total;
import mvm.primitives.Transpose;
import mvm.primitives.Tuple;
import mvm.primitives.Union;
import mvm.primitives.UnitFactor;
import mvm.primitives.Zip;
import mvm.values.Boole;
import mvm.values.PacioliList;
import mvm.values.PacioliValue;
import mvm.values.matrix.Entity;
import mvm.values.matrix.Index;
import mvm.values.matrix.IndexType;
import mvm.values.matrix.Matrix;
import mvm.values.matrix.MatrixType;

import units.Base;
import units.NamedUnit;
import units.PowerProduct;
import units.Prefix;
import units.ScaledUnit;
import units.Unit;
import units.UnitSystem;


public class Machine {
	
	public boolean verbose;
	
	private Environment store;
	private UnitSystem unitSystem;
	private HashMap<String, Entity> entities;
	private HashMap<Base, Unit[]> indices;
	
	public Machine() {
		verbose = false;
		store = new Environment();
		unitSystem = makeSI();
		entities = new HashMap<String, Entity>();
		indices = new HashMap<Base, Unit[]>();
		
		store.put("unitFactor", new UnitFactor());
		store.put("rowIndex", new RowIndex());
		store.put("columnIndex", new ColumnIndex());
		store.put("matrixFromTuples", new MatrixFromTuples());
		store.put("gcd", new Gcd());
		store.put("size", new Size());
		store.put("print", new Print());
		store.put("tuple", new Tuple());
		store.put("apply", new Apply());
		store.put("equal", new Equal());
		store.put("sum", new Sum());
		store.put("magnitude", new Magnitude());
		store.put("div", new Div());
		store.put("mod", new Mod());
		store.put("less", new Less());
		store.put("lessEq", new LessEq());
		store.put("get", new Get());
		store.put("put", new Put());
		store.put("set", new Set());
		store.put("isolate", new Isolate());
		store.put("multiply", new Multiply());
		store.put("reduceMatrix", new ReduceMatrix());
		store.put("loopMatrix", new LoopMatrix());
		store.put("reduce", new Reduce());
		store.put("reduceList", new ReduceList());
		store.put("loopList", new LoopList());
		store.put("reduceSet", new ReduceSet());
		store.put("addMut", new AddMut());
		store.put("adjoinMut", new AdjoinMut());
		store.put("append", new Append());
		store.put("head", new Head());
		store.put("tail", new Tail());
		store.put("identity", new Identity());
		store.put("singletonList", new SingletonList());
		store.put("join", new Join());
		store.put("scale", new Scale());
		store.put("total", new Total());
		store.put("transpose", new Transpose());
		store.put("reciprocal", new Reciprocal());
		store.put("negative", new Negative());
		store.put("abs", new Abs());
		store.put("indexLess", new IndexLess());
		store.put("closure", new PosSeries());
		store.put("kleene", new Kleene());
		store.put("singletonSet", new SingletonSet());
		store.put("union", new Union());					
		store.put("not", new Not());
		store.put("column", new Column());
		store.put("row", new Row());
		store.put("columnDomain", new ColumnDomain());
		store.put("rowDomain", new RowDomain());
		store.put("true", new Boole(true));
		store.put("false", new Boole(false));
		store.put("zip", new Zip());
		
	}
	
	public void run(String fileName, PrintStream out) throws IOException {
		Reader reader = new Reader(new FileReader(fileName), unitSystem);
		if (verbose) {
			out.format("-- Running file '%s'\n", fileName );
		}
		long before = System.currentTimeMillis();
		runStream(reader, out);
		long after = System.currentTimeMillis();
		if (verbose) {
			out.format("-- Ready in %d ms\n", after - before);
			out.println();
			dumpTypes(out);
			out.println();
			dumpState(out);
		}
	}
	
	private Matrix fetch(String name) throws IOException{
		if (!store.containsKey(name)) {
			throw new IOException(String.format("name '%s' unknown", name));
		}
		return (Matrix) store.lookup(name);
	}

	public void dumpTypes(PrintStream out) {
		out.println("-- Store signature:");
		for (Map.Entry<String,PacioliValue> entry: store.entrySet()) {
			if (entry.getValue() instanceof Matrix) {
				out.println(String.format("%s :: %s", entry.getKey(), ((Matrix) entry.getValue()).typeString()));
			} else {
				out.println(String.format("%s :: %s", entry.getKey(), "List"));	
			}
			
		}
	}

	public void dumpState(PrintStream out) {
		out.println("-- Store contents:");
		for (Map.Entry<String,PacioliValue> entry: store.entrySet()) {
			out.println(String.format("\n%s =\n%s", entry.getKey(), entry.getValue().pprint()));
		}
	}
	
	public List<Expression> readExpressionList(Reader reader) throws IOException{
		List<Expression> list = new ArrayList<Expression>();
		while (!reader.hasCharacter(')')) {
			list.add(readExpression(reader));
			if (reader.hasCharacter(',')) {
				reader.readCharacter(',');
			}
		}
		return list;
	}
	
	public List<String> readStringList(Reader reader) throws IOException{
		List<String> list = new ArrayList<String>();
		while (!reader.hasCharacter(')')) {
			list.add(reader.readIdentifier());
			if (reader.hasCharacter(',')) {
				reader.readCharacter(',');
			}
		}
		return list;
	}
		
	public void readCharacter(Reader reader, char character) throws IOException {
		reader.skipWhitespace();
		reader.readCharacter(character);
	}
	
	private Expression readExpression(Reader reader) throws IOException {
		reader.skipWhitespace();
		if (reader.hasNumber()) {
			return new Const(new Matrix(reader.readNumber()));
		} else if (reader.hasIdentifier()) {
			
			String command = reader.readIdentifier();
			if (command.equals("lambda")) {
				
				readCharacter(reader, '(');
				List<String> vars = readStringList(reader);
				readCharacter(reader, ')');
				Expression body = readExpression(reader);
				
				return new Lambda(vars,body);
				
			} else if (command.equals("application")) {
				reader.readCharacter('(');
				List<Expression> expressions = readExpressionList(reader);
				reader.readCharacter(')');
				Expression fun = expressions.remove(0); 
				return new Application(fun,expressions);
				
			} else if (command.equals("if")) {
				
				reader.readCharacter('(');
				Expression test = readExpression(reader);
				reader.readCharacter(',');
				Expression pos = readExpression(reader);
				reader.readCharacter(',');
				Expression neg = readExpression(reader);
				reader.readCharacter(')'); 
				return new Branch(test,pos,neg);
				
			} else if (command.equals("and")) {
				
				reader.readCharacter('(');
				Expression lhs = readExpression(reader);
				reader.readCharacter(',');
				Expression rhs = readExpression(reader);
				reader.readCharacter(')'); 
				return new And(lhs,rhs);
				
			} else if (command.equals("or")) {
				
				reader.readCharacter('(');
				Expression lhs = readExpression(reader);
				reader.readCharacter(',');
				Expression rhs = readExpression(reader);
				reader.readCharacter(')'); 
				return new Or(lhs,rhs);
				
			} else if (command.equals("bang")) {
				
				reader.readCharacter('(');
				IndexType indexType = reader.readIndexType();
//				String entity = reader.readIdentifier();
//				reader.readCharacter(',');
//				String unit = reader.readIdentifier();
				reader.readCharacter(')'); 
				
				Index index = new Index(indexType, entities, indices);
				
				return new Bang(index);
				
			} else {
				return new Variable(command);				
			}
		} else {
			throw new IOException(String.format("expected expression but found '%s'", reader.nextChars()));			
		}
	}
	
	private void runStream(Reader reader, PrintStream out) throws IOException {
		try {
			String command;
			reader.skipWhitespace();
			while (!reader.eof()) {
				if (reader.hasIdentifier()) {

					command = reader.readIdentifier();
					
					if (command.equals("log")) {
						
						String text = reader.readString();
						reader.readSeparator();
						
						out.print(text);
						
					} else if (command.equals("skip")) {
					
						reader.readSeparator();
					
					} else if (command.equals("dump")) {
						
						String source = reader.readIdentifier();
						String entityFile = reader.readString();
						String matrixFile = reader.readString();
						
						if (true) { //(verbose) {
							out.format("dumping basis %s into %s and %s", source, entityFile, matrixFile);
						}
						
						PacioliValue value = store.lookup(source);
						if (value instanceof PacioliList) {
							
							PacioliList list = (PacioliList) value;
							
							int index = 0;
							Matrix matrix;
							BufferedWriter entityStream = new BufferedWriter(new FileWriter(entityFile));
							BufferedWriter matrixStream = new BufferedWriter(new FileWriter(matrixFile));
							List<String> rowKey = new ArrayList<String>();
							
							for (PacioliValue item: list.items()) {
								
								entityStream.write(String.format("\"Conspiracy%s\";\n", index));
								
								if (item instanceof Matrix) {
									matrix = (Matrix) item;
									rowKey.clear();
									rowKey.add(String.format("Conspiracy%s", index));
									matrix.writeConspiracy(rowKey, matrixStream);
								} else {
									throw new RuntimeException("Value '<source>' to dump is not a list of matrices");
								}
								
								index++;
							}
							
							entityStream.close();
							matrixStream.close();
							
						} else {
							throw new RuntimeException("Value '<source>' to dump is not a list");
						}
						
					} else if (command.equals("load")) {
						
						String destination = reader.readIdentifier();
						String text = reader.readString();
						String unit = reader.readString();
						String row = reader.readString();
						String column= reader.readString();
						reader.readSeparator();
						
						Unit factor = parseUnit("", unit);
						IndexType rowType = parseIndexType(row);
						IndexType columnType = parseIndexType(column);
				
						Index rowIndex = new Index(rowType, entities, indices);
						Index columnIndex = new Index(columnType, entities, indices);
						MatrixType type = new MatrixType(factor, rowType, columnType);
						Matrix matrix = new Matrix(type, rowIndex, columnIndex);
						
						if (verbose) {
							out.format("-- Loading matrix '%s' from source '%s'\n", destination, text);
						}
						
						matrix.load(text);
						store.put(destination, matrix);
						
					} else if (command.equals("entity")) {

						String name = reader.readIdentifier();
						String source = reader.readString();
						reader.readSeparator();
						
						if (verbose) {
							out.format("-- Loading entity '%s' from source '%s'\n", name, source);
						}
						
						entities.put(name, new Entity(loadEntityFile(source)));
						
					} else if (command.equals("index")) {
						
						String entityName = reader.readIdentifier();
						String name = reader.readIdentifier();
						String file = reader.readString();
						reader.readSeparator();

						String symbol = entityName + "!" + name;

						Entity entity;
						if (entities.containsKey(entityName)) {
							entity = entities.get(entityName);
						} else {
							throw new IOException(String.format("Entity '%s' unnown", entityName));
						}
						
						if (verbose) {
							out.format("-- Loading index '%s' from file '%s'\n", symbol, file);
						}

						Map<String, Unit> units = loadUnitFile(file);
						
						Unit[] unitArray = new Unit[entity.size()];
						String key;
						for (int i=0; i<entity.size(); i++) {
							key = entity.ElementAt(i);
							if (units.containsKey(key)) {
								unitArray[i] = units.get(key);
							} else {
								unitArray[i] = new PowerProduct();
							}
						}
						
						Base unit = new NamedUnit(symbol);
						unitSystem.addUnit(symbol, unit);
						indices.put(unit, unitArray);
						
					} else if (command.equals("set")) {
						
						String destination = reader.readIdentifier();
						String source = reader.readIdentifier();
						reader.readSeparator();
						
						store.put(destination, fetch(source));
						
					} else if (command.equals("eval")) {
						
						String destination = reader.readIdentifier();
						Expression exp = readExpression(reader);
						reader.readSeparator();
						
						if (verbose) {
							out.format("-- Evaluating %s\n", exp.pprint());
						}
						
						store.put(destination, exp.eval(store));
						
					} else if (command.equals("conversion")) {
						
						String destination = reader.readIdentifier();
						String entity = reader.readString();
						String srcUnit = reader.readString();
						String dstUnit = reader.readString();
						reader.readSeparator();
						
						Unit factor = parseUnit("", "1"); 
						IndexType rowType = parseIndexType(entity + "!" + dstUnit);
						IndexType columnType = parseIndexType(entity + "!" + srcUnit);
						MatrixType type = new MatrixType(factor, rowType, columnType);
						
						Index rowIndex = new Index(rowType, entities, indices);
						Index columnIndex = new Index(columnType, entities, indices);
						
						if (verbose) {
							out.format("-- Creating conversion '%s' from '%s' to '%s'\n",
										destination, srcUnit, dstUnit);
						}
						
						Matrix matrix = new Matrix(type, rowIndex, columnIndex);
						matrix.loadConversion();
						
						store.put(destination, matrix);
						
					} else if (command.equals("projection")) {
						
						String destination = reader.readIdentifier(); 
						String row = reader.readString();
						String column = reader.readString();
						reader.readSeparator();
						
						IndexType rowType = parseIndexType(row);
						IndexType columnType = parseIndexType(column);
						MatrixType type = new MatrixType(new PowerProduct(), rowType, columnType);

						Index rowIndex = new Index(rowType, entities, indices);
						Index columnIndex = new Index(columnType, entities, indices);
						
						Matrix matrix = new Matrix(type, rowIndex, columnIndex);
						
						if (verbose) {
							out.format("-- Creating projection '%s' of '%s' per '%s'\n",
									destination, rowType.pprint(), columnType.pprint());
						}
						
						matrix.loadProjection();
						store.put(destination, matrix);
						
					} else if (command.equals("print")) {
						
						String source = reader.readIdentifier();
						reader.readSeparator();
						
						if (!store.containsKey(source)) {
							throw new IOException(String.format("name '%s' unknown", source));
						}
						
						out.println(store.lookup(source).pprint());
						
					} else if (command.equals("unit")) {

						String name = reader.readIdentifier();
						String symbol = reader.readString();
						Unit unit = reader.readUnit("");
						readCharacter(reader, ';');
						
						if (verbose) {
							out.format("-- Adding unit '%s' (%s) with %s = %s\n",
									name, symbol, symbol, unit.pprint());
						}
						
						unitSystem.addUnit(name, new NamedUnit(symbol, unit));
						
					} else if (command.equals("baseunit")) {

						String name = reader.readIdentifier();
						String symbol = reader.readString();
						reader.readSeparator();
						
						if (verbose) {
							out.format("-- Adding base unit '%s' (%s)\n", name, symbol );
						}
						
						unitSystem.addUnit(name, new NamedUnit(symbol));
						
						
					} else if (command.equals("abort")) {

						String reason = reader.readString();
						reader.readSeparator();

						throw new IOException(reason);
						
						
					} else {
						throw new IOException(String.format("command '%s' unknown", command));
					}
					
				} else {
					
					throw new IOException(String.format("expected command but found '%s'", reader.nextChar()));					
				}
				
				reader.skipWhitespace();
				
			}
		} catch (IOException e) {
			throw new IOException(String.format("at line %d: %s", reader.lineno(), e.getLocalizedMessage()));
		}
	}
	
	public List<String> loadEntityFile(String fileName) throws IOException{
		List<String> names = new ArrayList<String>();
		Reader reader = new Reader(new FileReader(fileName), unitSystem);
		String name;
		reader.skipWhitespace();
		while (!reader.eof()) {
			name = reader.readString();
			reader.skipWhitespace();
			if (!reader.eof()) {
				reader.readCharacter(';');
			}
			reader.skipWhitespace();
			names.add(name);
		}
		return names;
	}

	public Map<String, Unit> loadUnitFile(String fileName) throws IOException {
		Map<String, Unit> map = new HashMap<String, Unit>();
		Reader reader = new Reader(new FileReader(fileName), unitSystem);
		reader.skipWhitespace();
		while (!reader.eof()) {
			String name = reader.readString();
			Unit unit = reader.readUnit("");
			reader.skipWhitespace();
			if (!reader.eof()) {
				reader.readCharacter(';');
			}
			reader.skipWhitespace();
			map.put(name, unit);
		}
		return map;
	}
	
	private Unit parseUnit(String entity, String input) throws IOException{
		Reader reader = new Reader(new StringReader(input), unitSystem);
		Unit unit = reader.readUnit(entity);
		if (!reader.eof()) {
			throw new IOException(String.format("Trash after unit when reading '%s'", input));
		}
		return unit;
	}
	
	private IndexType parseIndexType(String input) throws IOException{
		Reader reader = new Reader(new StringReader(input), unitSystem);
		IndexType type = reader.readIndexType();
		if (!reader.eof()) {
			throw new IOException(String.format("Trash after index type when reading '%s'", input));
		}
		return type;
	}
	
	static private UnitSystem makeSI(){

		UnitSystem si = new UnitSystem();
		
		// The kilogram is the only base unit with a prefix and requires special handling.
		Prefix kilo = new Prefix("k", 1000);
		NamedUnit gram = new NamedUnit("g");
		
		// The prefixes of the SI. 
		si.addPrefix("giga", new Prefix("G", 1000000000));
		si.addPrefix("mega", new Prefix("M", 1000000));
		si.addPrefix("kilo", kilo);
		si.addPrefix("hecto", new Prefix("h", 100));
		si.addPrefix("deca", new Prefix("da", 10));
		si.addPrefix("deci", new Prefix("d", 0.1));
		si.addPrefix("centi", new Prefix("c", 0.01));
		si.addPrefix("milli", new Prefix("m", 0.001));
		si.addPrefix("micro", new Prefix("µ", 0.000001));
		si.addPrefix("nano", new Prefix("n", 0.000000001));

		// The base units of the SI.
		si.addUnit("metre", new NamedUnit("m"));
		si.addUnit("gram", gram);
		si.addUnit("second", new NamedUnit("s"));
		si.addUnit("ampere", new NamedUnit("A"));
		si.addUnit("kelvin", new NamedUnit("K"));
		si.addUnit("mole", new NamedUnit("mol"));
		si.addUnit("candela", new NamedUnit("cd"));
	
		// This is to make the kilogram the base unit instead of the gram 
		ScaledUnit kilogram = new ScaledUnit(kilo, gram);
		si.addUnit("kilogram", kilogram);
		gram.setDefinition(kilogram.multiply(0.001));
		kilogram.setDefinition(kilogram); 
		
		return si;
	}
}
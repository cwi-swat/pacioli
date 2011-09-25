package mvm;

import java.io.FileReader;
import java.io.IOException;
import java.io.PrintStream;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import mvm.expressions.And;
import mvm.expressions.Application;
import mvm.expressions.Branch;
import mvm.expressions.Const;
import mvm.expressions.Expression;
import mvm.expressions.Lambda;
import mvm.expressions.Or;
import mvm.expressions.Variable;
import mvm.primitives.Append;
import mvm.primitives.Apply;
import mvm.primitives.Columns;
import mvm.primitives.Equal;
import mvm.primitives.Get;
import mvm.primitives.Head;
import mvm.primitives.Identity;
import mvm.primitives.Isolate;
import mvm.primitives.Join;
import mvm.primitives.Kleene;
import mvm.primitives.LeftIdentity;
import mvm.primitives.LessEq;
import mvm.primitives.Magnitude;
import mvm.primitives.Multiply;
import mvm.primitives.Negative;
import mvm.primitives.Not;
import mvm.primitives.PosSeries;
import mvm.primitives.Put;
import mvm.primitives.Reciprocal;
import mvm.primitives.Reduce;
import mvm.primitives.ReduceList;
import mvm.primitives.ReduceMatrix;
import mvm.primitives.ReduceSet;
import mvm.primitives.RightIdentity;
import mvm.primitives.Rows;
import mvm.primitives.Scale;
import mvm.primitives.Set;
import mvm.primitives.SingletonList;
import mvm.primitives.SingletonSet;
import mvm.primitives.Sum;
import mvm.primitives.Tail;
import mvm.primitives.Total;
import mvm.primitives.Transpose;
import mvm.primitives.Tuple;
import mvm.primitives.Union;
import mvm.primitives.Zip;
import mvm.values.Boole;
import mvm.values.PacioliList;
import mvm.values.PacioliSet;
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
	
	private HashMap<String, PacioliValue> store;
	private UnitSystem unitSystem;
	private HashMap<String, Entity> entities;
	private HashMap<Base, Unit[]> indices;
	
	public Machine() {
		verbose = false;
		store = new HashMap<String, PacioliValue>();
		unitSystem = makeSI();
		entities = new HashMap<String, Entity>();
		indices = new HashMap<Base, Unit[]>();
	}
	
	public void run(String fileName, PrintStream out) throws IOException {
		Tokenizer tokenizer = new Tokenizer(new FileReader(fileName), unitSystem);
		if (verbose) {
			out.format("-- Running file '%s'\n", fileName );
		}
		long before = System.currentTimeMillis();
		runStream(tokenizer, out);
		long after = System.currentTimeMillis();
		if (verbose) {
			out.format("-- Ready in %d ms\n", after - before);
			out.println();
			dumpTypes(System.out);
			out.println();
			dumpState(System.out);
		}
	}
	
	private Matrix fetch(String name) throws IOException{
		if (!store.containsKey(name)) {
			throw new IOException(String.format("name '%s' unknown", name));
		}
		return (Matrix) store.get(name);
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
	
	public List<Expression> readExpressionList(Tokenizer tokenizer) throws IOException{
		List<Expression> list = new ArrayList<Expression>();
		int token = tokenizer.nextToken();
		while (token != ')') {
			tokenizer.pushBack();
			list.add(readExpression(tokenizer));
			token = tokenizer.nextToken();
			if (token == ',') {
				token = tokenizer.nextToken();
			}
		}
		tokenizer.pushBack();
		return list;
	}
	
	private Expression readExpression(Tokenizer tokenizer) throws IOException {
		int token = tokenizer.nextToken(); 
		switch (token) {
		case Tokenizer.TT_WORD:
			
			String command = tokenizer.sval();
								
			if (command.equals("lambda")) {
				
				tokenizer.readCharacter('(');
				List<String> vars = tokenizer.readIdentifierList();
				tokenizer.readCharacter(')');
				Expression body = readExpression(tokenizer);
				
				return new Lambda(vars,body);
				
			} else if (command.equals("application")) {
				tokenizer.readCharacter('(');
				List<Expression> expressions = readExpressionList(tokenizer);
				tokenizer.readCharacter(')');
				Expression fun = expressions.remove(0); 
				return new Application(fun,expressions);
				
			} else if (command.equals("if")) {
				
				tokenizer.readCharacter('(');
				Expression test = readExpression(tokenizer);
				tokenizer.readCharacter(',');
				Expression pos = readExpression(tokenizer);
				tokenizer.readCharacter(',');
				Expression neg = readExpression(tokenizer);
				tokenizer.readCharacter(')'); 
				return new Branch(test,pos,neg);
				
			} else if (command.equals("and")) {
				
				tokenizer.readCharacter('(');
				Expression lhs = readExpression(tokenizer);
				tokenizer.readCharacter(',');
				Expression rhs = readExpression(tokenizer);
				tokenizer.readCharacter(')'); 
				return new And(lhs,rhs);
				
			} else if (command.equals("or")) {
				
				tokenizer.readCharacter('(');
				Expression lhs = readExpression(tokenizer);
				tokenizer.readCharacter(',');
				Expression rhs = readExpression(tokenizer);
				tokenizer.readCharacter(')'); 
				return new Or(lhs,rhs);
				
			} else {
				return new Variable(command);				
			}			
			
		case Tokenizer.TT_NUMBER:
			// todo: read optional unit
			Unit factor = parseUnit("", "1"); 
			IndexType rowType = parseIndexType("empty");
			IndexType columnType = parseIndexType("empty");
			MatrixType type = new MatrixType(factor, rowType, columnType);
			
			Index rowIndex = new Index(rowType, entities, indices);
			Index columnIndex = new Index(columnType, entities, indices);
			
			Matrix matrix = new Matrix(type, rowIndex, columnIndex);
			return new Const(matrix.putDouble(0,0,tokenizer.dval()));
				
		default:
			throw new IOException(String.format("expected expression but found '%s'", (char) token));
		}
	}
	
	private void runStream(Tokenizer tokenizer, PrintStream out) throws IOException {
		try {
			for(int token = tokenizer.nextToken(); 
				token != Tokenizer.TT_EOF; 
				token = tokenizer.nextToken()) {
				switch (token) {
				case Tokenizer.TT_WORD:
					
					String command = tokenizer.sval();
										
					if (command.equals("log")) {
						
						String text = tokenizer.readString();
						tokenizer.readSeparator();
						
						out.print(text);
						
					} else if (command.equals("skip")) {
					
						tokenizer.readSeparator();
					
					} else if (command.equals("load")) {
						
						String destination = tokenizer.readIdentifier();
						String text = tokenizer.readString();
						String unit = tokenizer.readString();
						String row = tokenizer.readString();
						String column= tokenizer.readString();
						tokenizer.readSeparator();
						
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

						String name = tokenizer.readIdentifier();
						String source = tokenizer.readString();
						tokenizer.readSeparator();
						
						if (verbose) {
							out.format("-- Loading entity '%s' from source '%s'\n", name, source);
						}
						
						entities.put(name, new Entity(loadEntityFile(source)));
						
					} else if (command.equals("index")) {
						
						String entityName = tokenizer.readIdentifier();
						String name = tokenizer.readIdentifier();
						String file = tokenizer.readString();
						tokenizer.readSeparator();

						String symbol = entityName + "." + name;

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
						
						String destination = tokenizer.readIdentifier();
						String source = tokenizer.readIdentifier();
						tokenizer.readSeparator();
						
						store.put(destination, fetch(source));
						
					} else if (command.equals("eval")) {
						
						String destination = tokenizer.readIdentifier();
						Expression exp = readExpression(tokenizer);
						tokenizer.readSeparator();
						Environment env = new Environment();
						for (String name: store.keySet()) {
							env = env.extend(new Environment(name, store.get(name)));
						}
						env = env.extend(new Environment("tuple", new Tuple()));
						env = env.extend(new Environment("apply", new Apply()));
						env = env.extend(new Environment("equal", new Equal()));
						env = env.extend(new Environment("sum", new Sum()));
						env = env.extend(new Environment("magnitude", new Magnitude()));
						env = env.extend(new Environment("get", new Get()));
						env = env.extend(new Environment("put", new Put()));
						env = env.extend(new Environment("set", new Set()));
						env = env.extend(new Environment("isolate", new Isolate()));
						env = env.extend(new Environment("multiply", new Multiply()));
						env = env.extend(new Environment("reduceMatrix", new ReduceMatrix()));
						env = env.extend(new Environment("reduce", new Reduce()));
						env = env.extend(new Environment("reduceList", new ReduceList()));
						env = env.extend(new Environment("reduceSet", new ReduceSet()));
						env = env.extend(new Environment("append", new Append()));
						env = env.extend(new Environment("head", new Head()));
						env = env.extend(new Environment("tail", new Tail()));
						env = env.extend(new Environment("identity", new Identity()));
						env = env.extend(new Environment("singletonList", new SingletonList()));
						env = env.extend(new Environment("join", new Join()));
						env = env.extend(new Environment("scale", new Scale()));
						env = env.extend(new Environment("total", new Total()));
						env = env.extend(new Environment("transpose", new Transpose()));
						env = env.extend(new Environment("reciprocal", new Reciprocal()));
						env = env.extend(new Environment("negative", new Negative()));
						env = env.extend(new Environment("closure", new PosSeries()));
						env = env.extend(new Environment("kleene", new Kleene()));
						env = env.extend(new Environment("leftIdentity", new LeftIdentity()));
						env = env.extend(new Environment("rightIdentity", new RightIdentity()));
						env = env.extend(new Environment("singletonSet", new SingletonSet()));
						env = env.extend(new Environment("emptySet", new PacioliSet()));
						env = env.extend(new Environment("union", new Union()));						
						env = env.extend(new Environment("not", new Not()));
						env = env.extend(new Environment("columns", new Columns()));
						env = env.extend(new Environment("rows", new Rows()));
						env = env.extend(new Environment("true", new Boole(true)));
						env = env.extend(new Environment("false", new Boole(false)));
						env = env.extend(new Environment("emptyList", new PacioliList(new ArrayList<PacioliValue>())));
						env = env.extend(new Environment("zip", new Zip()));
						env = env.extend(new Environment("lessEq", new LessEq()));						
						
						if (verbose) {
							out.format("-- Evaluating %s\n", exp.pprint());
						}
						
						store.put(destination, exp.eval(env));
						
					} else if (command.equals("conversion")) {
						
						String destination = tokenizer.readIdentifier();
						String entity = tokenizer.readString();
						String srcUnit = tokenizer.readString();
						String dstUnit = tokenizer.readString();
						tokenizer.readSeparator();
						
						Unit factor = parseUnit("", "1"); 
						IndexType rowType = parseIndexType(entity + "." + dstUnit);
						IndexType columnType = parseIndexType(entity + "." + srcUnit);
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
						
						String destination = tokenizer.readIdentifier();
						String row = tokenizer.readString();
						String column = tokenizer.readString();
						tokenizer.readSeparator();
						
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
						
						String source = tokenizer.readIdentifier();
						tokenizer.readSeparator();
						
						if (!store.containsKey(source)) {
							throw new IOException(String.format("name '%s' unknown", source));
						}
						
						out.println(store.get(source).pprint());
						
					} else if (command.equals("unit")) {

						String name = tokenizer.readIdentifier();
						String symbol = tokenizer.readString();
						Unit unit = tokenizer.readUnit("");
						tokenizer.readSeparator();
						
						if (verbose) {
							out.format("-- Adding unit '%s' (%s) with %s = %s\n",
									name, symbol, symbol, unit.pprint());
						}
						
						unitSystem.addUnit(name, new NamedUnit(symbol, unit));
						
					} else if (command.equals("baseunit")) {

						String name = tokenizer.readIdentifier();
						String symbol = tokenizer.readString();
						tokenizer.readSeparator();
						
						if (verbose) {
							out.format("-- Adding base unit '%s' (%s)\n", name, symbol );
						}
						
						unitSystem.addUnit(name, new NamedUnit(symbol));
						
						
					} else if (command.equals("abort")) {

						String reason = tokenizer.readString();
						tokenizer.readSeparator();

						throw new IOException(reason);
						
						
					} else {
						throw new IOException(String.format("command '%s' unknown", command));
					}
					
					break;
					
				case Tokenizer.TT_NUMBER:
					throw new IOException("expected command but found number");
					
				default:
					throw new IOException(String.format("expected command but found '%s'", (char) token));
				}
			}
		} catch (IOException e) {
			throw new IOException(String.format("at line %d: %s", tokenizer.lineno(), e.getLocalizedMessage()));
		}
	}
	
	public List<String> loadEntityFile(String fileName) throws IOException{
		List<String> names = new ArrayList<String>();
		Tokenizer tokenizer = new Tokenizer(new FileReader(fileName), unitSystem);
		while (tokenizer.nextToken() != Tokenizer.TT_EOF) {
			tokenizer.pushBack();
			String name = tokenizer.readString();
			tokenizer.readSeparator();
			names.add(name);
		}
		tokenizer.pushBack();
		return names;
		
	}

	public Map<String, Unit> loadUnitFile(String fileName) throws IOException {
		Tokenizer tokenizer = new Tokenizer(new FileReader(fileName), unitSystem);
		Map<String, Unit> map = new HashMap<String, Unit>();
		while (tokenizer.nextToken() != Tokenizer.TT_EOF) {
			tokenizer.pushBack();
			String name = tokenizer.readString();
			Unit unit = tokenizer.readUnit("");
			tokenizer.readSeparator();
			map.put(name, unit);
		}
		tokenizer.pushBack();
		return map;
	}
	
	private Unit parseUnit(String entity, String input) throws IOException{
		Tokenizer tokenizer = new Tokenizer(new StringReader(input), unitSystem);
		Unit unit = tokenizer.readUnit(entity);
		if (tokenizer.nextToken() != Tokenizer.TT_EOF) {
			throw new IOException(String.format("Trash after unit when reading '%s'", input));
		}
		return unit;
	}
	
	private IndexType parseIndexType(String input) throws IOException{
		Tokenizer tokenizer = new Tokenizer(new StringReader(input), unitSystem);
		IndexType type = tokenizer.readIndexType();
		if (tokenizer.nextToken() != Tokenizer.TT_EOF) {
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
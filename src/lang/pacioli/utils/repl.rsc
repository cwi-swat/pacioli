module lang::pacioli::utils::repl

import List;
import String;
import IO;

import units::units;

import lang::pacioli::ast::Pacioli;
import lang::pacioli::ast::KernelPacioli;
import lang::pacioli::ast::SchemaPacioli;
import lang::pacioli::types::inference;
import lang::pacioli::compile::pacioli2mvm;
import lang::pacioli::types::Types;
import lang::pacioli::types::unification;
import lang::pacioli::utils::Implode;
import lang::pacioli::utils::implodeSchema;

////////////////////////////////////////////////////////////////////////////////
// Repl utilities
			  
alias Repo = map[str,tuple[Expression,Scheme]];
alias EntityRepo = map[str,str];
alias ProjectionRepo = map[str,tuple[IndexType,IndexType]];
alias ConversionRepo = map[str,tuple[str,str,str]];
alias IndexRepo = map[str,tuple[str,str,str]];
alias FileLocations = map[str,str];
alias BaseUnitRepo = map[str,str];
alias UnitRepo = map[str,tuple[str,Unit]];
  			  
BaseUnitRepo glbBaseUnitRepo = ();
UnitRepo glbUnitRepo = ();
Repo glbReplRepo = ();
Environment glbImports = ();
EntityRepo glbEntities = ();
ProjectionRepo glbProjections = ();
ConversionRepo glbConversions = ();
FileLocations glbFileLocations = ();
IndexRepo glbIndices = ();

list[str] glbReplRepoOrder = [];

int glbcounter = 100;

str fresh(str x) {glbcounter += 1; return "<x><glbcounter>";}

Environment totalEnv(repo, imports) {
	env = ();
	for (name <- repo) {
		<code,sch> = repo[name];
		env += (name:sch);
	}
	for (name <- imports) {
		env += (name:glbImports[name]);
	}
	return env;
}

public bool isFunction(forall(_,_,_, Type t)) {
	switch (t) {
	case function(_,_): return true;
	default: return false;
	}
}

public str addUnits(BaseUnitRepo bases, UnitRepo units) {
	baseStrings = ["baseunit <name> <bases[name]>" | name <- bases];
	unitStrings = ["unit <name> <symbol> <serial(unit)>" | name <- units, <symbol, unit> := units[name]];
	return intercalate(";\n", baseStrings + unitStrings); 
}

public str addEntities(EntityRepo repo) {
	return intercalate(";\n", ["entity <name> <repo[name]>" | name <- repo]);
}

public str addProjections(ProjectionRepo repo) {
	return intercalate(";\n", ["projection <name> \"<serial(row)>\" \"<serial(column)>\"" |
										name <- repo, <row,column> := repo[name]]);
}

public str addConversions(ConversionRepo repo) {
	return intercalate(";\n", ["conversion <name> \"<ent>\" \"<from>\" \"<to>\"" |
										name <- repo, <ent,to,from> := repo[name]]);
}

public str addIndices(IndexRepo repo) {
	return intercalate(";\n", ["index <ent> <idx> <path>" |
										name <- repo, <ent,idx,path> := repo[name]]);
}

public str addLoads(Environment env) {
	return intercalate(";\n", ["load <name> <glbFileLocations[name]> \"<serial(f)>\" \"<serial(r)>\" \"<serial(c)>\"" |
								name <- env,
								name in glbFileLocations,
								forall({},{},{},matrix(f,r,c)) := env[name]]);
}

public str addEvals(Repo repo) {
	defs = ["eval <name> <compilePacioli(code)>" | name <- glbReplRepoOrder, <code,sch> := repo[name]];
	return intercalate(";\n", defs);
}		

Scheme inferScheme(Expression exp, Environment env) {
	<expType, _> = inferTypeAPI(exp, env);
	niceType = unfresh(expType);
	return forall(unitVariables(niceType), entityVariables(niceType), typeVariables(niceType), niceType);
}

////////////////////////////////////////////////////////////////////////////////
// IDE hooks

public void importSchema(Schema schema) {
	imports = fetchImports(schema);
	for (path <- imports) {
		importSchemaFile(path);
	}
	baseUnits = fetchBaseUnits(schema);
	for (name <- baseUnits) {
		println("Base unit <name>: <baseUnits[name]>");
		glbBaseUnitRepo[name] = baseUnits[name];
	}
	units = fetchUnits(schema);
	for (name <- units) {
		<symbol, unit> = units[name];
		println("Unit <name>: <symbol> = <pprint(unit)>");
		glbUnitRepo[name] = units[name];
	}
	locations = fetchFileLocations(schema);
	for (name <- locations) {
		println("Quantity <name> <locations[name]>");
		glbFileLocations[name] = locations[name];
	}
	entities = fetchEntities(schema);
	for (name <- entities) {
		println("Entity <name> <entities[name]>");
		glbEntities[name] = entities[name];
	}
	indices = fetchIndices(schema);
	for (name <- indices) {
		<ent,idx,path> = indices[name];
		println("Index <ent> <idx> <path>");
		glbIndices[name] = indices[name];
	}
	projections = fetchProjections(schema);
	for (name <- projections) {
		<row,column> = projections[name];
		println("Projection <name> <row> <column>");
		glbProjections[name] = projections[name];
		matrixType = matrix(uno(), row, column);
		glbImports[name] = forall({},{},{},matrixType);
	}
	conversions = fetchConversions(schema);
	for (name <- conversions) {
		<ent,to,from> = conversions[name];
		println("Conversion <name> <ent> <from> <to>");
		matrixType = matrix(uno(), duo(compound([simple(ent)]), named(to,to,self())), duo(compound([simple(ent)]), named(from,from,self())));
		glbConversions[name] = conversions[name];
		glbImports[name] = forall({},{},{},matrixType);
	}
	environment = translateSchema(schema);
	for (name <- environment) {
		println("<name> :: <pprint(environment[name])>");
		glbImports += (name: environment[name]);
	}
}

public void reset() {
	glbBaseUnitRepo = ();
	glbUnitRepo = ();
	glbReplRepo = ();
	glbImports = ();
	glbEntities = ();
	glbProjections = ();
	glbConversions = ();
	glbFileLocations = ();
	glbIndices = ();
	glbReplRepoOrder = [];
}

public void compile(Module mod) {

	reset();
	
	pacioliModule(items) = mod;
		
	for (item <- items) {
		switch (item) {
		case schemaImport(s): {
			path = substring(s,1,size(s)-1);
			importSchemaFile(path);
		}
		case fileImport(s): {
			path = substring(s,1,size(s)-1);
			compileFile(path);
		}
		case valueDefinition(x,y): {
			def(x,y);
		}
		case functionDefinition(x,y,z): {
			def(x, abstraction(y,z));
		}
		}
	}
	
	expressions = [x | topLevelExpression(x) <- items];
	if (expressions != []) {
		// todo: the tail!
		compile(head(expressions));
	}
}

public void compile(Expression exp) {
	fullEnv = totalEnv(glbReplRepo, glbImports);

	scheme = inferScheme(exp, fullEnv);
	println("<pprint(exp)> :: <pprint(scheme)>");
	
	programStrings = [addUnits(glbBaseUnitRepo, glbUnitRepo),
					  addEntities(glbEntities),
					  addIndices(glbIndices),
					  addLoads(fullEnv),
					  addProjections(glbProjections),
					  addConversions(glbConversions),
					  addEvals(glbReplRepo),
					  "eval result <compilePacioli(exp)>",
					  "print result"];
					 
	prog = intercalate(";\n", programStrings - [""]);
	   	   
	writeFile(|project://pacioli/cases/tmp.mvm|, [prog]);
}

////////////////////////////////////////////////////////////////////////////////
// Some commands

public void compile(str exp) {
	try {
		compile(parseImplodePacioli(exp));
	} catch err: {
		println(err);
	}
}

public void importSchema(str schema) {
	importSchema(parseImplodeSchema(schema));
}

public void importSchemaFile(str path) {
	text = intercalate("\n", readFile(path));
	importSchema(text);
}

public void compileFile(str path) {
	text = intercalate("\n", readFile(path));
	compile(text);
}

public void ls () {
	env = totalEnv(glbReplRepo, glbImports);
	for (name <- env) {
		if (!isFunction(env[name])) {
			println("<name> :: <pprint(env[name])>");
		}
	}
}

public void functions () {
	env = totalEnv(glbReplRepo, glbImports);
	for (name <- env) {
		if (isFunction(env[name])) {
			println("<name> :: <pprint(env[name])>");
		}
	}
}

public void parse (str exp) {
	parsed = parseImplodePacioli(exp);
	println(pprint(parsed));
	println(parsed);
}

public void def(str name, Expression exp) {
	try {
		parsed = exp;
		env = totalEnv(glbReplRepo, glbImports);
		
		// hack for recursive functions
		f = fresh("def");
		env += (name: forall({},{},{},typeVar(f)));

		scheme = inferScheme(parsed, env);
		
		glbReplRepo += (name: <parsed,scheme>);
		glbReplRepoOrder -= name;
		glbReplRepoOrder += name;
		
		println("<name> :: <pprint(scheme)>");
		
	} catch err: {
		println(err);
	}
}

public void def(str name, str exp) {
	return def(name, parseImplodePacioli(exp));
}

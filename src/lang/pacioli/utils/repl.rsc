module lang::pacioli::utils::repl

import List;
import IO;

import units::units;

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

public str addUnits(str prelude, BaseUnitRepo bases, UnitRepo units) {
	baseStrings = ["baseunit <name> <bases[name]>" | name <- bases];
	unitStrings = ["unit <name> <symbol> <serial(unit)>" | name <- units, <symbol, unit> := units[name]];
	return intercalate(";\n", baseStrings + unitStrings); 
}

public str addEntities(str prelude, EntityRepo repo) {
	return intercalate(";\n", ["entity <name> \"<repo[name]>\"" | name <- repo]);
}

public str addProjections(str prelude, ProjectionRepo repo) {
	return intercalate(";\n", ["projection <name> \"<serial(row)>\" \"<serial(column)>\"" |
										name <- repo, <row,column> := repo[name]]);
}

public str addConversions(str prelude, ConversionRepo repo) {
	return intercalate(";\n", ["conversion <name> \"<ent>\" \"<from>\" \"<to>\"" |
										name <- repo, <ent,to,from> := repo[name]]);
}

public str addIndices(str prelude, IndexRepo repo) {
	return intercalate(";\n", ["index <ent> <idx> \"<path>\"" |
										name <- repo, <ent,idx,path> := repo[name]]);
}

public str addLoads(str prelude, Environment env) {
	return intercalate(";\n", ["load <name> \"<glbFileLocations[name]>\" \"<serial(f)>\" \"<serial(r)>\" \"<serial(c)>\"" |
								name <- env,
								name in glbFileLocations,
								forall({},{},{},matrix(f,r,c)) := env[name]]);
}

public str addEvals(str prelude, Repo repo) {
	funs = ["eval <name> <compilePacioli(code)>" | name <- glbReplRepoOrder, 
												   <code,sch> := repo[name], 
												   isFunction(sch)];
	nonfuns = ["eval <name> <compilePacioli(code)>" | name <- glbReplRepoOrder, 
													  <code,sch> := repo[name], 
													  !isFunction(sch)];
	return intercalate(";\n", funs + nonfuns);
}		

Scheme inferScheme(Expression exp, Environment env) {
	<expType, _> = inferTypeAPI(exp, env);
	niceType = unfresh(expType);
	return forall(unitVariables(niceType), entityVariables(niceType), typeVariables(niceType), niceType);
}

////////////////////////////////////////////////////////////////////////////////
// IDE hooks

public void importSchema(Schema schema) {
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
		println("Quantity <name> \"<locations[name]>\"");
		glbFileLocations[name] = locations[name];
	}
	entities = fetchEntities(schema);
	for (name <- entities) {
		println("Entity <name> \"<entities[name]>\"");
		glbEntities[name] = entities[name];
	}
	indices = fetchIndices(schema);
	for (name <- indices) {
		<ent,idx,path> = indices[name];
		println("Index <ent> <idx> \"<path>\"");
		glbIndices[name] = indices[name];
	}
	projections = fetchProjections(schema);
	for (name <- projections) {
		<row,column> = projections[name];
		println("Projection <name> <row> <column>");
		glbProjections[name] = projections[name];
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

public void compile(Expression exp) {
	fullEnv = totalEnv(glbReplRepo, glbImports);

	scheme = inferScheme(exp, fullEnv);
	println("<pprint(exp)>\n  :: <pprint(scheme)>");
	
	header = "";
	preludeStrings = [addUnits(header, glbBaseUnitRepo, glbUnitRepo),
					  addEntities(header, glbEntities),
					  addIndices(header, glbIndices),
					  addLoads(header,fullEnv),
					  addProjections(header,glbProjections),
					  addConversions(header,glbConversions),
					  addEvals(header,glbReplRepo)];
	prog = "<intercalate(";\n", preludeStrings - [""])>;
	   	   'eval result <compilePacioli(exp)>; 
       	   'print result";
       	   
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

public void def(str name, str exp) {
	try {
		parsed = parseImplodePacioli(exp);
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

////////////////////////////////////////////////////////////////////////////////
// Standaard Library

public void stdLib() {
	def("combis", "lambda (list) 
		             let (result, dummy) = loopList(tuple([],list),
							                        lambda(accu,x)
							                          let (result,tails) = accu in
	 						                            tuple(append([tuple(x,y) | y in list tail(tails)], result), tail(tails))
	 						                          end,
	 						                        list) in
	 		           result
	 		         end");
	def("columns", "lambda (matrix) [column(matrix,j) | j in list columnDomain(matrix)]");
	def("rows", "lambda (matrix) [row(matrix,i) | i in list rowDomain(matrix)]");
	def("magnitudeMatrix", "lambda (mat) \<i,j -\> magnitude(mat,i,j) | i,j in matrix mat\>");
	def("unitMatrix", "lambda (mat) scale(unitFactor(mat), rowIndex(mat) per columnIndex(mat))");
	def("support", "lambda (x) \<i,j -\> 1 | i,j in matrix x, not(magnitude(x,i,j) = 0)\>");
	def("leftIdentity", "lambda (x) \<i,i -\> 1 | i in list rowDomain(x)\> * (rowIndex(x) per rowIndex(x))");
	def("rightIdentity", "lambda (x) \<j,j -\> 1 | j in list columnDomain(x)\> * (columnIndex(x) per columnIndex(x))");
	def("positives", "lambda (x) x * \<i,j -\> 1 | i,j in matrix x, 0 \< magnitude(x,i,j)\>");
	def("negatives", "lambda (x) x * \<i,j -\> 1 | i,j in matrix x, magnitude(x,i,j) \< 0\>");
}

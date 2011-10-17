module lang::pacioli::utils::repl

import List;
import IO;
import util::Prompt;

import units::units;

import lang::pacioli::ast::KernelPacioli;
import lang::pacioli::ast::SchemaPacioli;
import lang::pacioli::types::inference;
import lang::pacioli::compile::pacioli2mvm;
import lang::pacioli::compile::pacioli2java;
import lang::pacioli::types::Types;
import lang::pacioli::types::unification;
import lang::pacioli::utils::Implode;
import lang::pacioli::utils::dictionary;
import lang::pacioli::utils::implodeSchema;

////////////////////////////////////////////////////////////////////////////////
// Repl utilities
			  
alias Repo = map[str,tuple[Expression,Scheme]];
  			  
Repo glbReplRepo = ();

list[str] glbReplRepoOrder = [];

int glbcounter = 100;

str fresh(str x) {glbcounter += 1; return "<x><glbcounter>";}

public bool isFunction(forall(_,_,_, Type t)) {
	switch (t) {
	case function(_,_): return true;
	default: return false;
	}
}

public str addLoads(str prelude, Environment env) {
	text = prelude;
	for (name <- env) {
		if (forall({},{},{},matrix(f,r,c)) := env[name] && name in fileLoc) {
			text = text + ";\nload <name> \"<glbCasesDirectory><fileLoc[name]>\" \"<serial(f)>\" \"<serial(r)>\" \"<serial(c)>\"";
		}
	}
	return text;
}

public str addEvals(str prelude, Repo repo) {
	text = prelude;
	// Two passes to support some dependencies
	for (name <- glbReplRepoOrder) {
		<code,sch> = repo[name];
		if (isFunction(sch)) {
			text += ";\neval <name> <compilePacioli(code)>";
		}
	}
	for (name <- glbReplRepoOrder) {
		<code,sch> = repo[name];
		if (!isFunction(sch)) {
			text += ";\neval <name> <compilePacioli(code)>";
		}
	}
	return text;
}		

////////////////////////////////////////////////////////////////////////////////
// IDE hooks

Environment glbImports = ();

public void importSchema(Schema schema) {
	environment = translateSchema(schema);
	println("IMPORT");
	//println("IMPORT str <translated>");
	for (name <- environment) {
		println("<name> :: <pprint(environment[name])>");
		glbImports += (name: environment[name]);
	}
	//for (name <- glbImports) {
	//	println("<name> :: <pprint(glbImports[name])>");
	//}
}

public void compile(Expression exp) {
	try {
		fullEnv = ();
		
		for (name <- glbReplRepo) {
			<code,sch> = glbReplRepo[name];
			fullEnv += (name:sch);
		}
		for (name <- glbImports) {
			fullEnv += (name:glbImports[name]);
		}
		header = addLoads(prelude(),fullEnv);
		header = addEvals(header,glbReplRepo);
		
		<typ, _> = inferTypeAPI(exp, fullEnv);
		ty = unfresh(typ);
		scheme = forall(unitVariables(ty),
				        entityVariables(ty),
				        typeVariables(ty),
				        ty);
		println("<pprint(exp)>\n  :: <pprint(scheme)>");
		code = compilePacioli(exp);
		prog = "<header>;
		   	   'eval result <code>; 
	       	   'print result";		
		writeFile(|project://pacioli/cases/tmp.mvm|, [prog]);
	} catch err: {
		println(err);
	}
}

////////////////////////////////////////////////////////////////////////////////
// Some commands

public void importSchema(str schema) {
	parsed = parseImplodeSchema(schema);
	importSchema(parsed);
}

public void ls () {
	Environment env = ();
	for (name <- glbReplRepo) {
		<code,sch> = glbReplRepo[name];
		env += (name:sch);
	}
	for (name <- glbImports) {
			env += (name:glbImports[name]);
		}
	for (name <- env) {
		if (!isFunction(env[name])) {
			println("<name> :: <pprint(env[name])>");
		}
	}
}

public void functions () {
	Environment env = ();
	for (name <- glbReplRepo) {
		<code,sch> = glbReplRepo[name];
		env += (name:sch);
	}
	for (name <- glbImports) {
			env += (name:glbImports[name]);
		}
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

//public void parseSchema (str exp) {
//	parsed = parseImplodeSchema(exp);
//	println(pprint(parsed));
//	println(parsed);
//}

public void compile(str exp) {
	try {
		fullEnv = ();
		
		for (name <- glbReplRepo) {
			<code,sch> = glbReplRepo[name];
			fullEnv += (name:sch);
		}
		for (name <- glbImports) {
			fullEnv += (name:glbImports[name]);
		}
		header = addLoads(prelude(),fullEnv);
		header = addEvals(header,glbReplRepo);
		
		parsed = parseImplodePacioli(exp);
		<typ, _> = inferTypeAPI(parsed, fullEnv);
		ty = unfresh(typ);
		scheme = forall(unitVariables(ty),
				        entityVariables(ty),
				        typeVariables(ty),
				        ty);
		println("<exp>\n  :: <pprint(scheme)>");
		code = compilePacioli(parsed);
		prog = "<header>;
		   	   'eval result <code>; 
	       	   'print result";		
		writeFile(|file:///<glbCasesDirectory>tmp.mvm|, [prog]);
	} catch err: {
		println(err);
	}
}

public void def(str name, str exp) {
	try {
		parsed = parseImplodePacioli(exp);
		full = parsed;
		fullEnv = ();
		for (n <- glbReplRepo) {
			<code,sch> = glbReplRepo[n];
			fullEnv += (n:sch);
		}
		for (n <- glbImports) {
			fullEnv += (n:glbImports[n]);
		}
		// hack for recursive functions
		f = fresh("def");
		fullEnv += (name: forall({},{},{},typeVar(f)));
		
		<typ, s> = inferTypeAPI(full, fullEnv);
		typ = unfresh(typ);
 		// to make sure it compiles later on		
		//compilePacioli(full);
		scheme = forall(unitVariables(typ),
				entityVariables(typ),
				typeVariables(typ),
				typ);

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
}

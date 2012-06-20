module lang::pacioli::ide::Pacioli

import lang::pacioli::utils::Parse;
import lang::pacioli::utils::Implode;
import lang::pacioli::utils::parseSchema;
import lang::pacioli::utils::implodeSchema;
import lang::pacioli::syntax::Pacioli;
import lang::pacioli::ast::Pacioli;
import lang::pacioli::syntax::SchemaPacioli;
import lang::pacioli::ast::SchemaPacioli;
import lang::pacioli::utils::repl;
import util::Prompt;

import util::IDE;
import IO;

private str PACIOLI_LANG = "Pacioli";
private str SCHEMA_LANG = "Schema";



public void registerPacioli() {
	registerLanguage(PACIOLI_LANG, "pacioli", parsePacioli);
	registerLanguage(SCHEMA_LANG, "schema", parseSchema);
	contribs = {
		popup(
			menu(PACIOLI_LANG,[
	    		action("Compile", compilePacioliFile)
		    ])
	  	)
	};
	registerContributions(PACIOLI_LANG, contribs);
	contribs = {
		popup(
			menu(SCHEMA_LANG,[
	    		action("Import", compileSchemaFile)
		    ])
	  	)
	};
	registerContributions(SCHEMA_LANG, contribs);
}

public void compilePacioliFile(lang::pacioli::syntax::Pacioli::Module modu, loc l) {
	try {
		reset();
		ast = normalizeModule(implode(modu));
		compile(ast);
	} catch err: {
		println(err);
		alert("Error while compiling Pacioli expression. See console for more information.");
	}
}

public void compileSchemaFile(lang::pacioli::syntax::SchemaPacioli::Schema exp, loc l) {
	try {
		ast = normalizeSchema(implodeSchema(exp));
		importSchema(ast);
 		alert("Schema imported.");
 	} catch err: {
		println(err);
		alert("Error while importing schema. See console for more information.");
	}
}

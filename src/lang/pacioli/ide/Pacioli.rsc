module lang::pacioli::ide::Pacioli

import lang::pacioli::utils::Parse;
import lang::pacioli::utils::Implode;
import lang::pacioli::utils::parseSchema;
import lang::pacioli::utils::implodeSchema;
import lang::pacioli::syntax::KernelPacioli;
import lang::pacioli::ast::KernelPacioli;
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

//public void registerSchema() {
//	registerLanguage(PACIOLI_LANG, "pacioli", parsePacioli);
//	registerLanguage(PACIOLI_LANG, "schema", parseSchema);
//	contribs = {
//		popup(
//			menu(PACIOLI_LANG,[
//	    		action("Compile", compilePacioliFile),
//	    		action("Import", compileSchemaFile)
//		    ])
//	  	)
//  };
//  registerContributions(PACIOLI_LANG, contribs);
//}

public void compilePacioliFile(lang::pacioli::syntax::KernelPacioli::Expression exp, loc l) {
  ast = normalize(implode(exp));
  compile(ast);
  alert("compilation done");
}

public void compileSchemaFile(lang::pacioli::syntax::SchemaPacioli::Schema exp, loc l) {
	ast = normalizeSchema(implodeSchema(exp));
	//ast = exp;
	importSchema(ast);
 	alert("schema imported");
}
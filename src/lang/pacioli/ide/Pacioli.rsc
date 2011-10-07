module lang::pacioli::ide::Pacioli

import lang::pacioli::utils::Parse;
import lang::pacioli::utils::Implode;
import lang::pacioli::syntax::KernelPacioli;
import lang::pacioli::ast::KernelPacioli;
import lang::pacioli::utils::repl;
import util::Prompt;

import util::IDE;
import IO;

private str PACIOLI_LANG = "Pacioli";



public void registerPacioli() {
	registerLanguage(PACIOLI_LANG, "pacioli", parsePacioli);
	contribs = {
		popup(
			menu(PACIOLI_LANG,[
	    		action("Compile", compilePacioliFile) 
		    ])
	  	)
  };
  registerContributions(PACIOLI_LANG, contribs);
}

public void compilePacioliFile(lang::pacioli::syntax::KernelPacioli::Expression exp, loc l) {
  ast = normalize(implode(exp));
  compile(ast);
  alert("compilation done");
}
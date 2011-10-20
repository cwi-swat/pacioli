module lang::pacioli::utils::Parse

//import lang::pacioli::syntax::KernelPacioli;
import lang::pacioli::syntax::Pacioli;

import ParseTree;

public Module parsePacioli(str x, loc l) {
	return parse(#Module, x, l);
}

public Module parsePacioliFile(str x, loc l) {
	start[Module] pt = parse(#start[Module], x, l);
	return pt.tree;
}


public Module parsePacioli(str x) {
	return parsePacioli(x, |file://-|);
}


module lang::pacioli::utils::Parse

import lang::pacioli::syntax::KernelPacioli;
import lang::pacioli::syntax::Pacioli;

import ParseTree;

public Expression parsePacioli(str x, loc l) {
	return parse(#Expression, x, l);
}

public Expression parsePacioliFile(str x, loc l) {
	start[Expression] pt = parse(#start[Expression], x, l);
	return pt.tree;
}


public Expression parsePacioli(str x) {
	return parsePacioli(x, |file://-|);
}


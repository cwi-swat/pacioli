module lang::pacioli::utils::Parse

import lang::pacioli::syntax::KernelPacioli;


import ParseTree;

public Expression parsePacioli(str x, loc l) {
	return parse(#Expression, x, l);
}


public Expression parsePacioli(str x) {
	return parsePacioli(x, |file://-|);
}


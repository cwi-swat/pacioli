module lang::pacioli::utils::Parse

import lang::pacioli::syntax::Lexical;
import lang::pacioli::syntax::Equations;


import ParseTree;

public Pacioli parsePacioli(str x, loc l) {
	return parse(#Pacioli, x, l);
}

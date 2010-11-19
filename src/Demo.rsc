module Demo

import ParseTree;
import languages::pacioli::syntax::Pacioli;
import languages::pacioli::ast::Pacioli;

alias CPacioli = languages::pacioli::syntax::Pacioli::Pacioli;
alias APacioli = languages::pacioli::ast::Pacioli::Pacioli;

public CPacioli parsePacioli(str src) {
  return parse(#languages::pacioli::syntax::Pacioli::Pacioli, src);
}


public APacioli implodePacioli(CPacioli pt) {
  return implode(#APacioli, pt); 
}



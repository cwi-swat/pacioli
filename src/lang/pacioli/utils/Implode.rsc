module lang::pacioli::utils::Implode

import lang::pacioli::ast::KernelPacioli;
//import lang::pacioli::syntax::KernelPacioli;
import lang::pacioli::ast::Pacioli;
import lang::pacioli::syntax::Pacioli;
import lang::pacioli::utils::Parse;

import ParseTree;

public lang::pacioli::ast::Pacioli::Module implode(lang::pacioli::syntax::Pacioli::Module pt) {
	return implode(#lang::pacioli::ast::Pacioli::Module, pt);
}


public lang::pacioli::ast::Pacioli::Module parseImplodePacioli(str code) = normalizeModule(implode(parsePacioli(code)));

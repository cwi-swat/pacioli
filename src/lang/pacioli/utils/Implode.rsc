module lang::pacioli::utils::Implode

import lang::pacioli::ast::KernelPacioli;
import lang::pacioli::syntax::KernelPacioli;
import lang::pacioli::utils::Parse;

import ParseTree;

public lang::pacioli::ast::KernelPacioli::Expression implode(lang::pacioli::syntax::KernelPacioli::Expression pt) {
	return implode(#lang::pacioli::ast::KernelPacioli::Expression, pt);
}


public lang::pacioli::ast::KernelPacioli::Expression parseImplodePacioli(str code) = normalize(implode(parsePacioli(code)));

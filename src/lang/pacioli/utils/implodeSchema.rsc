module lang::pacioli::utils::implodeSchema

import lang::pacioli::ast::SchemaPacioli;
import lang::pacioli::syntax::SchemaPacioli;
import lang::pacioli::utils::parseSchema;

import ParseTree;

public lang::pacioli::ast::SchemaPacioli::Schema implodeSchema(lang::pacioli::syntax::SchemaPacioli::Schema pt) {
	return implode(#lang::pacioli::ast::SchemaPacioli::Schema, pt);
}


public lang::pacioli::ast::SchemaPacioli::Schema parseImplodeSchema(str code) = normalizeSchema(implodeSchema(parseSchema(code)));

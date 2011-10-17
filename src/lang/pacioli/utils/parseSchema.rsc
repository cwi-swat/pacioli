module lang::pacioli::utils::parseSchema

import lang::pacioli::syntax::SchemaPacioli;

import ParseTree;

public Schema parseSchema(str x, loc l) {
	return parse(#Schema, x, l);
}

public Schema parseSchemaFile(str x, loc l) {
	start[Schema] pt = parse(#start[Schema], x, l);
	return pt.tree;
}


public Schema parseSchema(str x) {
	return parseSchema(x, |file://-|);
}


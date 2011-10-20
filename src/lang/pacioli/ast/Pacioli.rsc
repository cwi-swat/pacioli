module lang::pacioli::ast::Pacioli

import List;

import lang::pacioli::ast::KernelPacioli;
import lang::pacioli::syntax::KernelPacioli;

//data Pacioli = Pacioli(Module mod);

data Module = pacioliModule(list[ModuleItem] items);

data ModuleItem
	= schemaImport(str path)
	| fileImport(str path)
	| topLevelExpression(Expression exp)
	| valueDefinition(str name, Expression exp)
	| functionDefinition(str fn, list[str] args, Expression body);

//data Expression =  Const(real number);

//anno loc Pacioli@location;
anno loc Module@location;
//anno loc Definition@location;
//anno loc Expression@location;




public Module normalizeModule(pacioliModule(items)) {
	return pacioliModule([normalizeItem(item) | item <- items]);
}

public ModuleItem normalizeItem(ModuleItem item) {
	switch (item) {
	case schemaImport(x): return item;
	case fileImport(x): return item;
	case topLevelExpression(x): return topLevelExpression(normalize(x));
	case valueDefinition(x,y): return valueDefinition(x,normalize(y));
	case functionDefinition(fn,args,body): return functionDefinition(fn,args,normalize(body));
	}
}

public str pprint(pacioliModule(items)) {
	return intercalate(";\n", [pprint(x) | x <- items]);
}

public str pprint(ModuleItem item) {
	switch (item) {
	case schemaImport(x): return "Import <x>";
	case fileImport(x): return "Include <x>";
	case topLevelExpression(x): return pprint(x);
	case valueDefinition(x,y): return "<x> = <pprint(y)>";
	case functionDefinition(fn,args,body): return "<fn>(<intercalate(", ", args)>) = <pprint(body)>";
	}
}
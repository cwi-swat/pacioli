module lang::pacioli::utils::repl

import IO;

import units::units;

import lang::pacioli::ast::KernelPacioli;
import lang::pacioli::types::inference;
import lang::pacioli::compile::pacioli2mvm;
import lang::pacioli::compile::pacioli2java;
import lang::pacioli::types::Types;
import lang::pacioli::types::unification;
import lang::pacioli::utils::Implode;

////////////////////////////////////////////////////////////////////////////////
// Hardwired Data Schema 

str glbCasesDirectory = "/home/paul/data/code/cwi/pacioli/cases/";

str prelude = "baseunit dollar \"$\";
			  'baseunit euro \"�\";
			  'baseunit each \"each\";
			  'baseunit bag \"bag\";
			  'baseunit case \"case\";
			  'baseunit can \"can\";
			  'baseunit tub \"tub\";
			  'baseunit gal \"gal\";
			  'baseunit roll \"roll\";
			  'baseunit sleeve \"sleeve\";
			  'baseunit box \"box\";
			  'baseunit bottle \"bottle\";
			  'unit litre \"l\" (deci metre)^3;
			  'unit pound \"lb\" 0.45359237*kilo gram;
			  'unit ounce \"oz\" pound/16;
			  'unit barrel \"bbl\" 117.347765*litre;
	          'entity Product \"<glbCasesDirectory>case1/product.entity\";
			  'index Product bom_unit \"<glbCasesDirectory>case1/product.bom_unit\";
			  'index Product trade_unit \"<glbCasesDirectory>case1/product.trade_unit\";
			  'entity Commodity \"<glbCasesDirectory>case2/commodity.entity\";
			  'entity Year \"<glbCasesDirectory>case2/year.entity\";
			  'entity Region \"<glbCasesDirectory>case2/region.entity\";
			  'index Commodity unit \"<glbCasesDirectory>case2/commodity.unit\";
			  'entity Ingredient \"<glbCasesDirectory>case3/ingredient.entity\";
			  'entity Menu \"<glbCasesDirectory>case3/menu.entity\";
			  'index Ingredient unit \"<glbCasesDirectory>case3/ingredient.unit\";
			  'conversion conv \"Product\" \"bom_unit\" \"trade_unit\";
			  'projection P0 \"Commodity,Year,Region.1\" \"Commodity.1\";
			  'projection P1 \"Commodity,Year,Region.1\" \"Commodity,Year.1\";
			  'projection P2 \"Year,Commodity.1,unit\" \"Commodity,Year,Region.unit,1,1\";
			  'entity Place \"<glbCasesDirectory>case4/place.entity\";
			  'entity Transition \"<glbCasesDirectory>case4/transition.entity\";
			  'index Place unit \"<glbCasesDirectory>case4/place.unit\"";


map[str,str] fileLoc = 
	("output":             "case1/output.csv",
	 "sales_price":        "case1/sales_price.csv",
	 "purchase_price":     "case1/purchase_price.csv",
	 "bom":                "case1/bom.csv",
	 "sales":              "case2/sales.csv",
	 "amount":             "case2/amount.csv",
	 "semi_bom":           "case3/semi_bom.csv",
	 "ingredient_price":   "case3/ingredient_price.csv",
	 "menu_sales":         "case3/menu_sales.csv",
	 "menu_price":         "case3/menu_price.csv",
	 "stock1":             "case3/stock1.csv",
	 "stock2":             "case3/stock2.csv",
	 "forward":            "case4/forward.csv",
	 "backward":           "case4/backward.csv");

public Environment env() {

	Unit gram = named("gram", "g", self());
	Unit metre = named("metre", "m", self());
	Unit second = named("second", "s", self());
	Unit dollar = named("dollar", "$", self());
	Unit euro = named("euro", "�", self());

	IndexType empty = duo(compound([]), uno());
	
	EntityType Product = compound([simple("Product")]);
	Unit tradeUnit = named("trade_unit", "trade_unit", self());
	Unit bomUnit = named("bom_unit", "bom_unit", self());
	
	IndexType tradeIndex = duo(Product, tradeUnit);
	IndexType bomIndex = duo(Product, bomUnit);
	
	SimpleEntity Commodity = simple("Commodity");
	SimpleEntity Year = simple("Year");
	SimpleEntity Region = simple("Region");
	Unit commodityUnit = named("unit", "unit", self());

	EntityType Ingredient = compound([simple("Ingredient")]);
	EntityType Menu = compound([simple("Menu")]);
	Unit ingredientUnit = named("unit", "unit", self());
	
	IndexType ingredientIndex = duo(Ingredient, ingredientUnit);
	
	SimpleEntity Place = simple("Place");
	SimpleEntity Transition = simple("Transition");
	Unit placeUnit = named("unit", "unit", self());
	
	IndexType placeIndex = duo(compound([Place]), placeUnit);
	
  return (
   "gram": forall({},{},{}, matrix(gram, empty, empty)),
   "metre": forall({},{},{}, matrix(metre, empty, empty)),
   "second": forall({},{},{}, matrix(second, empty, empty)),
   "dollar": forall({},{},{}, matrix(dollar, empty, empty)),
   "euro": forall({},{},{}, matrix(euro, empty, empty)),
   "bom": forall({},{},{}, matrix(uno(), bomIndex, bomIndex)),
   "conv": forall({},{},{}, matrix(uno(), tradeIndex, bomIndex)),
   "output": forall({},{},{}, matrix(uno(), tradeIndex, empty)),
   "purchase_price": forall({},{},{}, matrix(dollar, empty, tradeIndex)),
   "sales_price": forall({},{},{}, matrix(dollar, empty, tradeIndex)),
   "sales": forall({},{},{}, matrix(dollar, empty, duo(compound([Commodity, Year, Region]), uno()))),
   "amount": forall({},{},{}, matrix(uno(), duo(compound([Commodity, Year, Region]), compoundUnit([commodityUnit, uno(), uno()])), empty)),
   "P0": forall({},{},{}, matrix(uno(), duo(compound([Commodity, Year, Region]), uno()), duo(compound([Commodity]), uno()))),
   "P1": forall({},{},{}, matrix(uno(), duo(compound([Commodity, Year, Region]), uno()), duo(compound([Commodity, Year]), uno()))),   
   "P2": forall({},{},{}, matrix(uno(), duo(compound([Year, Commodity]), compoundUnit([uno(), commodityUnit])),
                                        duo(compound([Commodity, Year, Region]), compoundUnit([commodityUnit, uno(), uno()])))),
   "P3": forall({},{},{}, matrix(uno(), duo(compound([Year]), uno()),
                                        duo(compound([Commodity, Year, Region]), compoundUnit([commodityUnit, uno(), uno()])))),
   "semi_bom": forall({},{},{}, matrix(uno(), ingredientIndex, duo(Menu, uno()))),
   "ingredient_price": forall({},{},{}, matrix(dollar, empty, ingredientIndex)),
   "menu_sales": forall({},{},{}, matrix(uno(), duo(Menu, uno()), empty)),
   "menu_price": forall({},{},{}, matrix(dollar, empty, duo(Menu, uno()))),
   "stock1": forall({},{},{}, matrix(uno(), ingredientIndex, empty)),
   "stock2": forall({},{},{}, matrix(uno(), ingredientIndex, empty)),
   "forward": forall({},{},{}, matrix(uno(), placeIndex, duo(compound([Transition]), uno()))),
   "backward": forall({},{},{}, matrix(uno(), placeIndex, duo(compound([Transition]), uno()))),
   "empty": forall({},{},{"a"},listType(typeVar("a"))),   
   "join": forall({"a", "b", "u", "v", "w"},{"P", "Q", "R"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  					   duo(entityVar("P"), unitVar("u")),
  				  					   duo(entityVar("Q"), unitVar("v"))),
  				  				matrix(unitVar("b"), 
  				  					   duo(entityVar("Q"), unitVar("v")),
  				  					   duo(entityVar("R"), unitVar("w")))]),
				           matrix(multiply(unitVar("a"), unitVar("b")), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("R"), unitVar("w"))))),
	"transpose": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v")))]),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("Q"), reciprocal(unitVar("v"))),
  				  				  duo(entityVar("P"), reciprocal(unitVar("u")))))),
	"total": forall({"a"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), uno()),
  				  				  duo(entityVar("Q"), uno()))]),
				           matrix(unitVar("a"), 
  				  				  empty,
  				  				  empty))),
	"sqrt": forall({"a"},{},{},
  				  function(tupType([matrix(multiply(unitVar("a"),unitVar("a")), 
  				  				  duo(compound([]), uno()),
  				  				  duo(compound([]), uno()))]),
				           matrix(unitVar("a"), 
  				  				  duo(compound([]), uno()),
  				  				  duo(compound([]), uno())))),
   "sum": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  					   duo(entityVar("P"), unitVar("u")),
  				  					   duo(entityVar("Q"), unitVar("v"))),
  				  				matrix(unitVar("a"), 
  				  					   duo(entityVar("P"), unitVar("u")),
  				  					   duo(entityVar("Q"), unitVar("v")))]),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))))),
   "multiply": forall({"a", "b", "u", "v", "w", "z"},{"P", "Q"},{},
				function(tupType([matrix(unitVar("a"), 
  				  					 duo(entityVar("P"), unitVar("u")),
  				  					 duo(entityVar("Q"), unitVar("v"))),
  				  			  matrix(unitVar("b"), 
  				  					 duo(entityVar("P"), unitVar("w")),
  				  					 duo(entityVar("Q"), unitVar("z")))]),
				         matrix(multiply(unitVar("a"), unitVar("b")), 
  				  				duo(entityVar("P"), multiply(unitVar("u"), unitVar("w"))),
  				  				duo(entityVar("Q"), multiply(unitVar("v"), unitVar("z")))))),
   "negative": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v")))]),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))))),
   "closure": forall({"u"},{"P"},{},
  				  function(tupType([matrix(uno(), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("P"), unitVar("u")))]),
				           matrix(uno(), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("P"), unitVar("u"))))),
   "reciprocal": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v")))]),
				           matrix(reciprocal(unitVar("a")), 
  				  				  duo(entityVar("P"), reciprocal(unitVar("u"))),
  				  				  duo(entityVar("Q"), reciprocal(unitVar("v")))))),
	"equal": forall({},{},{"a"},
  				  function(tupType([typeVar("a"),typeVar("a")]), boolean())),
	"identity": forall({},{},{"a"},
  				  function(tupType([typeVar("a")]), typeVar("a"))),  				  
  	"true": forall({},{},{}, boolean()),
  	"false": forall({},{},{}, boolean()),
  	//"and": forall({},{},{},
  	//			  function(tupType([boolean(),boolean()]), boolean())),
  	//"or": forall({},{},{},
  	//			  function(tupType([boolean(),boolean()]), boolean())),
  	"not": forall({},{},{},
  				  function(tupType([boolean()]), boolean())),
  	"reduce": forall({},{},{"a", "b"},
  				  function(tupType([typeVar("b"),
  				  					function(tupType([typeVar("a")]), typeVar("b")),
  				  					function(tupType([typeVar("b"), typeVar("b")]), typeVar("b")),
  									listType(typeVar("a"))]), 
  				  		   typeVar("b"))),
	"head": forall({},{},{"a"},
  				  function(tupType([listType(typeVar("a"))]), typeVar("a"))),
  	"tail": forall({},{},{"a"},
  				  function(tupType([listType(typeVar("a"))]), listType(typeVar("a")))),
  	"single": forall({},{},{"a"},
  				  function(tupType([typeVar("a")]), listType(typeVar("a")))),
  	"append": forall({},{},{"a"},
  				  function(tupType([listType(typeVar("a")),listType(typeVar("a"))]), listType(typeVar("a")))),
  	"iter": forall({},{},{"a", "b"},
  				  function(tupType([function(tupType([typeVar("a")]), listType(typeVar("b"))), 
  				  		   			listType(typeVar("a"))]), 
  				  		   listType(typeVar("b")))),
	"columns": forall({"a", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  				           duo(entityVar("P"), unitVar("v")),
  				  				           duo(entityVar("Q"), uno()))]),
				           listType(matrix(unitVar("a"), 
  				  				   		   duo(entityVar("P"), unitVar("v")),
  				  				   		   empty)))),
	"rows": forall({"a", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  				           duo(entityVar("P"), uno()),
  				  				           duo(entityVar("Q"), unitVar("v")))]),
				           listType(matrix(unitVar("a"), 
				             			   empty,
  				  				   		   duo(entityVar("Q"), unitVar("v")))))));
}

////////////////////////////////////////////////////////////////////////////////
// Repl utilities

public str extendPrelude(str prelude, Environment env) {
	text = prelude;
	for (name <- env) {
		if (forall({},{},{},matrix(f,r,c)) := env[name] && name in fileLoc) {
			text += ";\nload <name> \"<glbCasesDirectory><fileLoc[name]>\" \"<serial(f)>\" \"<serial(r)>\" \"<serial(c)>\"";
		}
	}
	return text;
}

Expression blend(Expression exp, map[str,Expression] repo) {
	blended = exp;
	for (b <- repo) {
		blended = application(abstraction([b],blended),tup([repo[b]]));
	}
	return blended;
}
	
////////////////////////////////////////////////////////////////////////////////
// The repl
			  
map[str,Expression] glbReplRepo = ();

public void ep (str exp) {
	try {
		parsed = parseImplodePacioli(exp);
		full = blend(parsed,glbReplRepo);
		<typ, _> = inferTypeAPI(full, env());
		println("<pprint(parsed)> :: <pprint(unfresh(typ))>");
		code = compilePacioli(full, extendPrelude(prelude, env()));		
		writeFile(|file:///<glbCasesDirectory>tmp.mvm|, [code]);
		//writeFile(|file:///home/paul/data/code/cwi/pacioli/cases/tmp.mvm|, [code]);
		//writeFile(|file:///D:/code/cwi/pacioli/cases/tmp.mvm|, [code]);
		//writeFile(|project://Pacioli/cases/tmp.mvm|, [code]);
	} catch err: {
		println(err);
	}
}

// Dirty hack to fake definitions
public void def(str name, str exp) {
	try {
		parsed = parseImplodePacioli(exp);
		full = blend(parsed,glbReplRepo);
		<typ, _> = inferTypeAPI(full, env());
 		// to make sure it is not a function and does not compile later on		
		compilePacioli(full,extendPrelude(prelude, env()));
		glbReplRepo += (name: full);
		println("<name> :: <pprint(unfresh(typ))>");
		println("<name> = <pprint(parsed)>");
	} catch err: {
		println(err);
	}
}

public void ep2(str exp) {
	try {
		parsed = parseImplodePacioli(exp);
		full = blend(parsed,glbReplRepo);
		<typ, _> = inferTypeAPI(full, env());
		println("<pprint(parsed)> :: <pprint(unfresh(typ))>");
		code = compileToJava(full);
		println(code);		
		//writeFile(|file:///home/paul/data/code/cwi/pacioli/cases/tmp.mvm|, [code]);
		writeFile(|file:///home/paul/data/code/cwi/pacioli/cases/tmp.java|, [code]);
		//writeFile(|file:///D:/code/cwi/pacioli/cases/tmp.mvm|, [code]);
		//writeFile(|project://Pacioli/cases/tmp.mvm|, [code]);
	} catch err: {
		println(err);
	}
}

////////////////////////////////////////////////////////////////////////////////
// Demos
public void demo1() {

	println("\nBase units are pre-defined");
	show("gram");
	show("metre");
	
	println("\nUnits can always be multiplied");
	show("multiply(gram,gram)");
	show("multiply(gram,metre)");
	
	println("\nUnits can not always be summed");
	show("sum(gram,gram)");
	show("sum(gram,metre)");
	
	println("\nThe type is semantic, the order of multiplication is irrelevant");
	show("sum(multiply(gram,metre),multiply(gram,metre))");
	show("sum(multiply(gram,metre),multiply(metre,gram))");
	
	println("\nThe type system does inference.");
	show("lambda (x) sum(multiply(x,metre),multiply(gram,metre))");
	
	println("\nThe type system derives a most general type."); 
	show("lambda (x,y) sum(multiply(x,y),multiply(gram,metre))");
	show("(lambda (x) lambda (y) sum(multiply(x,y),multiply(gram,metre))) (gram)");
}

public void demo15() {

	println("\nBase units are pre-defined");
	show("gram");
	show("metre");
	
	println("\nUnits can always be multiplied");
	show("gram * gram");
	show("gram * metre");
	
	println("\nUnits can not always be summed");
	show("gram + gram");
	show("gram + metre");
	
	println("\nThe type is semantic, the order of multiplication is irrelevant");
	show("gram*metre + gram*metre");
	show("gram*metre + metre*gram");
	
	println("\nThe type system does inference.");
	show("lambda (x) x*metre + gram*metre");
	
	println("\nThe type system derives a most general type."); 
	show("lambda (x,y) x*y + gram*metre");
	show("(lambda (x) lambda (y) x*y + gram*metre) (gram)");
	show("(lambda (x,y) x*y + gram*metre)(gram,metre)");
	show("(lambda (x,y) x*y + gram*metre)(metre,gram)");
	show("(lambda (x,y) x*y + gram*metre)(metre*second,gram*second)");
	show("(lambda (x,y) x*y + gram*metre)(metre*second,gram/second)");
}
	
public void demo2() {
	
	// General
	show("lambda (x) join(x,x)");
	show("lambda (x) sum(sum(x,x),sum(x,x))");
	show("lambda (x) multiply(sum(x,x),sum(x,x))");
	show("lambda (x,y) join(sum(x,negative(y)),sum(y,negative(x)))");
	
	// Norm
	show("lambda (x) total(multiply(x,x))");
	show("lambda (x) sqrt(total(multiply(x,x)))");
	
	// Lie algebras
	show("lambda (x,y) sum(join(x,y),negative(join(y,x)))");
	
	// Netting problem
	show("lambda (x) join(bom,x)");
	show("(lambda (bom2) join(bom2,output)) (join(conv,join(bom,reciprocal(transpose(conv)))))");
	show("(lambda (bom2) closure(bom2)) (join(conv,join(bom,reciprocal(transpose(conv)))))");
	
	// Salesdata
	show("multiply(sales,reciprocal(transpose(amount)))");
	show("(lambda (price) multiply(join(price, reciprocal(transpose(P2))),join(price, reciprocal(transpose(P2))))) (multiply(sales,reciprocal(transpose(amount))))");
	show("(lambda (price) join(price, reciprocal(transpose(P2)))) (multiply(sales,reciprocal(transpose(amount))))");
	
	// Restaurant
	show("join(menu_price,menu_sales)");
	show("multiply(menu_price,transpose(menu_sales))");
}

	
public void demo25() {
	
	// General
	show("lambda(x) x.x");
	show("lambda(x) x+x+x+x");
	show("lambda(x) (x+x)*(x+x)");
	show("lambda(x,y) (x-y).(y-x)");
	
	// Norm
	show("lambda(x) total(x*x)");
	show("lambda(x) sqrt(total(x*x))");
	
	// Lie algebras
	show("lambda(x,y) x.y-y.x");
	
	// Netting problem
	show("lambda(x) bom o x");
	show("lambda(x) bom.x");
	show("(lambda(x) x o output) (conv o bom o 1/conv^T)");
	show("(lambda(x) x . output) (conv . bom . 1/conv^T)");
	show("(lambda(x) closure(x)) (conv.bom.1/conv^T)");
	show("(lambda(x) closure(x) . output) (conv . bom . 1/conv^T)");
	show("(lambda(f) closure(f(bom)) . output) (lambda (x) conv . x . 1/conv^T)");
	
	// Salesdata
	show("sales / amount^T");
	show("(lambda(price) (price . 1/P2^T) * (price . 1/P2^T)) (sales / amount^T)");
	show("(lambda(price) price.1/P2^T * price.1/P2^T) (sales / amount^T)");
	show("(lambda(price) (price . 1/P2^T)) (sales / amount^T)");
	show("(lambda(price) price.1/P2^T) (sales / amount^T)");
	
	// Restaurant
	show("menu_price . menu_sales");
	show("menu_price * menu_sales^T");
}


public void show (str exp) {
	try {
		parsed = parseImplodePacioli(exp);
		println("parsed code = <pprint(parsed)>");
		<typ, _> = inferTypeAPI(parsed, env());
		println("<exp> :: <pprint(unfresh(typ))>");
	} catch err: {
		println(err);
	}	
}



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
			  'baseunit loc \"loc\";
			  'baseunit bit \"bit\";
			  'unit byte \"byte\" 8*bit;
			  'unit hour \"hr\" 3600*second;
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
			  'index Place unit \"<glbCasesDirectory>case4/place.unit\";
			  'entity File \"<glbCasesDirectory>case5/file.entity\";
			  'entity Module \"<glbCasesDirectory>case5/module.entity\"";


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
	 "backward":           "case4/backward.csv",
	 "valuation":          "case4/valuation.csv",
	 "owner":              "case5/owner.csv",
	 "parent":             "case5/parent.csv",
	 "size":               "case5/size.csv",
	 "lines":              "case5/lines.csv",
	 "root":               "case5/root.csv");

public Environment env() {

	Unit gram = named("gram", "g", self());
	Unit metre = named("metre", "m", self());
	Unit second = named("second", "s", self());
	Unit dollar = named("dollar", "$", self());
	Unit euro = named("euro", "�", self());
	Unit linesOfCode = named("loc", "loc", self());
	Unit byte = named("byte", "byte", self());

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
	
	SimpleEntity File = simple("File");
	SimpleEntity Module = simple("Module");
	
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
   "valuation": forall({},{},{}, matrix(dollar,empty, placeIndex)),
   "owner": forall({},{},{}, matrix(uno(),duo(compound([File]), uno()), duo(compound([Module]), uno()))),
   "parent": forall({},{},{}, matrix(uno(),duo(compound([Module]), uno()), duo(compound([Module]), uno()))),
   "lines": forall({},{},{}, matrix(linesOfCode,empty, duo(compound([File]), uno()))),
   "size": forall({},{},{}, matrix(byte,empty, duo(compound([File]), uno()))),
   "root": forall({},{},{}, matrix(uno(), duo(compound([Module]), uno()),empty)),
   "emptyList": forall({},{},{"a"},listType(typeVar("a"))),   
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
   "scale": forall({"a", "b", "u", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), empty, empty),
  				  				matrix(unitVar("b"), 
  				  					   duo(entityVar("P"), unitVar("u")),
  				  					   duo(entityVar("Q"), unitVar("v")))]),
				           matrix(multiply(unitVar("a"), unitVar("b")), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))))),
	"magnitude": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  					       duo(entityVar("P"), unitVar("u")),
  				  					       duo(entityVar("Q"), unitVar("v"))),
  				  				    entity(entityVar("P")),
  				  					entity(entityVar("Q"))]),
				           matrix(uno(), 
  				  				  empty,
  				  				  empty))),  				  				  
	"isolate": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  					       duo(entityVar("P"), unitVar("u")),
  				  					       duo(entityVar("Q"), unitVar("v"))),
  				  				    entity(entityVar("P")),
  				  					entity(entityVar("Q"))]),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))))),
	"get": forall({"a"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  					       duo(entityVar("P"), uno()),
  				  					       duo(entityVar("Q"), uno())),
  				  				    entity(entityVar("P")),
  				  					entity(entityVar("Q"))]),
				           matrix(unitVar("a"), 
  				  				  empty,
  				  				  empty))),
	"put": forall({"a"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  					       duo(entityVar("P"), uno()),
  				  					       duo(entityVar("Q"), uno())),
  				  				    entity(entityVar("P")),
  				  					entity(entityVar("Q")),
  				  					matrix(unitVar("a"), empty, empty)]),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), uno()),
  				  				  duo(entityVar("Q"), uno())))),
	"set": forall({"a"},{"P", "Q"},{},
  				  function(tupType([entity(entityVar("P")),
  				  					entity(entityVar("Q")),
  				  					matrix(unitVar("a"), empty, empty)]),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), uno()),
  				  				  duo(entityVar("Q"), uno())))),
	"rowDomain": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  					       duo(entityVar("P"), unitVar("u")),
  				  					       duo(entityVar("Q"), unitVar("v")))]),
				           listType(entity(entityVar("P"))))),
	"transpose": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v")))]),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("Q"), reciprocal(unitVar("v"))),
  				  				  duo(entityVar("P"), reciprocal(unitVar("u")))))),
	"leftIdentity": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v")))]),
				           matrix(uno(), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("P"), unitVar("u"))))),
	"rightIdentity": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v")))]),
				           matrix(uno(), 
  				  				  duo(entityVar("Q"), unitVar("v")),
  				  				  duo(entityVar("Q"), unitVar("v"))))),
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
	"lessEq": forall({"a", "u", "v"},{"P", "Q"},{},
				function(tupType([matrix(unitVar("a"), 
  				  					 duo(entityVar("P"), unitVar("u")),
  				  					 duo(entityVar("Q"), unitVar("v"))),
  				  			  matrix(unitVar("a"), 
  				  					 duo(entityVar("P"), unitVar("u")),
  				  					 duo(entityVar("Q"), unitVar("v")))]),
				         boolean())),
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
	"kleene": forall({"u"},{"P"},{},
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
	"abs": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
   				  				           duo(entityVar("P"), unitVar("u")),
  				  				           duo(entityVar("Q"), unitVar("v")))]),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))))),  				  				  
	"equal": forall({},{},{"a"},
  				  function(tupType([typeVar("a"),typeVar("a")]), boolean())),
	"identity": forall({},{},{"a"},
  				  function(tupType([typeVar("a")]), typeVar("a"))),  				  
  	"true": forall({},{},{}, boolean()),
  	"false": forall({},{},{}, boolean()),
  	"not": forall({},{},{},
  				  function(tupType([boolean()]), boolean())),
  	"apply": forall({},{},{"a", "b"},
  				  function(tupType([function(typeVar("a"), typeVar("b")),
  				  					typeVar("a")]), 
  				  		   typeVar("b"))),
	"zip": forall({},{},{"a", "b"},
  				  function(tupType([listType(typeVar("a")),
  									listType(typeVar("b"))]), 
  				  		   listType(tupType([typeVar("a"),typeVar("b")])))),
  	"reduce": forall({},{},{"a", "b"},
  				  function(tupType([typeVar("b"),
  				  					function(tupType([typeVar("a")]), typeVar("b")),
  				  					function(tupType([typeVar("b"), typeVar("b")]), typeVar("b")),
  									listType(typeVar("a"))]), 
  				  		   typeVar("b"))),
  	"reduceList": forall({},{},{"a", "b", "c"},
  				  function(tupType([typeVar("b"),
  				  					function(tupType([typeVar("a")]), typeVar("c")),
  				  					function(tupType([typeVar("b"), typeVar("c")]), typeVar("b")),
  									listType(typeVar("a"))]), 
  				  		   typeVar("b"))),
	"reduceSet": forall({},{},{"a", "b"},
  				  function(tupType([typeVar("b"),
  				  					function(tupType([typeVar("a")]), typeVar("b")),
  				  					function(tupType([typeVar("b"), typeVar("b")]), typeVar("b")),
  									setType(typeVar("a"))]), 
  				  		   typeVar("b"))),  				  		   
  	"reduceMatrix": forall({"a", "u", "v"},{"P", "Q"},{"b"},
		function(tupType([typeVar("b"),
  					      function(tupType([entity(entityVar("P")), entity(entityVar("Q"))]),
  				  			 	   typeVar("b")),
  						  function(tupType([typeVar("b"), typeVar("b")]), typeVar("b")),
						  matrix(unitVar("a"), 
  				  				 duo(entityVar("P"), unitVar("u")),
  				  				 duo(entityVar("Q"), unitVar("v")))]), 
  		   		 typeVar("b"))),
	"emptySet": forall({},{},{"a"},setType(typeVar("a"))),
  	"singletonSet": forall({},{},{"a"},
		function(tupType([typeVar("a")]), setType(typeVar("a")))),
  	"union": forall({},{},{"a"},
  				  function(tupType([setType(typeVar("a")),setType(typeVar("a"))]), setType(typeVar("a")))),
  	"head": forall({},{},{"a"},
  				  function(tupType([listType(typeVar("a"))]), typeVar("a"))),
  	"tail": forall({},{},{"a"},
  				  function(tupType([listType(typeVar("a"))]), listType(typeVar("a")))),
  	"singletonList": forall({},{},{"a"},
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
		blended = let(b,repo[b],blended);
	}
	return blended;
}

////////////////////////////////////////////////////////////////////////////////
// The repl
			  
map[str,Expression] glbReplRepo = ();

public void ls () {
	Environment env = env();
	for (name <- env) {
		println("<name> :: <pprint(env[name])>");
	}
	for (name <- glbReplRepo) {
		println("<name> :: <pprint(glbReplRepo[name])>");
	}
}

public void parse (str exp) {
	parsed = parseImplodePacioli(exp);
	//println(pprint(parsed));
	println(parsed);
}

public void ep (str exp) {
	try {
		parsed = parseImplodePacioli(exp);
		full = blend(parsed,glbReplRepo);
		<typ, _> = inferTypeAPI(full, env());
		println("<exp> :: <pprint(unfresh(typ))>");
		code = compilePacioli(parsed);
		header = extendPrelude(prelude,env());
		for (name <- glbReplRepo) {
			header += ";\neval <name> <compilePacioli(glbReplRepo[name])>";
		}
		prog = "<header>;
		   	   'eval result <code>; 
	       	   'print result";		
		writeFile(|file:///<glbCasesDirectory>tmp.mvm|, [prog]);
	} catch err: {
		println(err);
	}
}

public void def(str name, str exp) {
	try {
		parsed = parseImplodePacioli(exp);
		full = blend(parsed,glbReplRepo);
		<typ, _> = inferTypeAPI(full, env());
 		// to make sure it compiles later on		
		compilePacioli(full);
		glbReplRepo += (name: parsed);
		println("<name> :: <pprint(unfresh(typ))>");
		println("<name> = <exp>");
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
	show("gram * gram");
	show("gram * metre");
	
	println("\nUnits can not always be summed");
	show("gram + gram");
	println("\ngram + metre gives an error:");
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
	
	println("\nMultiplying left and right is not allowed. A multiplication and division cancel");
	println("\n(lambda (x,y) x*y + gram*metre)(metre*second,gram*second) gives an error:"); 
	show("(lambda (x,y) x*y + gram*metre)(metre*second,gram*second)");
	show("(lambda (x,y) x*y + gram*metre)(metre*second,gram/second)");
}
	
public void demo2() {
	
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
	show("lambda(x) bom.x");
	show("(lambda(x) x . output) (conv . bom . conv^R^T)");
	show("(lambda(x) closure(x)) (conv.bom.conv^R^T)");
	show("(lambda(x) closure(x) . output) (conv . bom . conv^R^T)");
	show("(lambda(f) closure(f(bom)) . output) (lambda (x) conv . x . conv^R^T)");
	
	// Salesdata
	show("sales / amount^T");
	show("(lambda(price) (price . P2^R^T) * (price . P2^R^T)) (sales / amount^T)");
	show("(lambda(price) price.P2^R^T * price.P2^R^T) (sales / amount^T)");
	show("(lambda(price) (price . P2^R^T)) (sales / amount^T)");
	show("(lambda(price) price.P2^R^T) (sales / amount^T)");
	
	// Restaurant
	show("menu_price . menu_sales");
	show("menu_price * menu_sales^T");
}

public void demo3() {

	println("\nThe quantities involved");
	show("backward");
	show("forward");
	show("backward-forward");
	show("valuation");
	show("valuation.(backward-forward)");
		
	println("\nSome comprehensions");
	show("columns(backward-forward)");
	show("[x | x in columns(backward-forward)]");
	show("[x | x in columns(backward-forward), not(valuation.x = 0)]");
	show("count[x | x in columns(backward-forward)]");
	show("count[x | x in columns(backward-forward), not(valuation.x = 0)]");
	show("[val | x in columns(backward-forward), val := valuation.x, not(val = 0)]");
	show("sum[x | x in columns(backward-forward), not(valuation.x = 0)]");
	show("valuation . sum[x | x in columns(backward-forward), not(valuation.x = 0)]");
	
	println("\nSome abstractions");
	show("lambda (a) a . sum[x | x in columns(backward-forward), not(valuation.x = 0)]");
	show("lambda (a) valuation . sum[x | x in columns(a-forward), not(valuation.x = 0)]");
	show("(lambda (a) valuation . sum[x | x in columns(a-forward), not(valuation.x = 0)])(backward)");
	show("(lambda (a) valuation . sum[x | x in columns(a-forward), not(valuation.x = 0)])(forward)");
}

public void demo4() {

	println("\nQuantities");
	show("lines");
	show("size");
	show("owner");
	show("parent");

	println("\nAggregations");
	show("size.owner");
	show("size.owner.parent");
	show("size.owner.parent*");
	
	println("\nComprehensions");
	show("[x | x in columns(owner), not(x=0)]");
	show("[lines.x | x in columns(owner), not(x=0)]");
	show("[size.x/lines.x | x in columns(owner), not(x=0)]");
	show("[total(x) | x in columns(owner), x=0]");
	show("[t | x in columns(owner), t := total(x), t=0]");
	show("count[t | x in columns(owner), t := total(x), t=0]");
	
	println("\nAggregation functions.");
	show("lambda (x) x.owner.parent*");
	show("let agg = lambda(x) x.owner.parent* in agg(lines) end");
	//show("(lambda (agg) agg(size)/agg(lines)) (lambda (x) x.owner.parent*)");
	show("let agg = lambda(x) x.owner.parent* in agg(size)/agg(lines) end");
	
}

public void demo5() {
	ep(
"let dice = [1,2,3,4,5,6] in
   let sums = [x+y | x in dice, y in dice] in
     let total = count[s | s in sums] in
	   let cnt(n) = count[s | s in sums, s=n] in
	     [tuple[i,cnt(i)/total] | i elt {x+y | x in dice, y in dice}]
	   end
	 end
   end
 end");
}

public void demo6() {
	
	println("Some fun with lattices I");
	show("[negative]");
	show("[transpose]");
	show("[reciprocal]");
	show("[negative, transpose]");
	show("[negative, reciprocal]");
	show("[transpose, reciprocal]");
	show("[negative, transpose, reciprocal]");
	
	println("Some fun with lattices II");
	show("[identity, negative]");
	show("[identity, transpose]");
	show("[identity, reciprocal]");
	show("[identity, negative, transpose]");
	show("[identity, negative, reciprocal]");
	show("[identity, transpose, reciprocal]");
	show("[identity, negative, transpose, reciprocal]");
	
	println("Some fun with lattices of binary functions I");
	show("[join]");
	show("[sum]");
	show("[multiply]");
	show("[join, sum]");
	show("[join, multiply]");
	show("[sum, multiply]");
	show("[join, sum, multiply]");
	
	println("Some fun with lattices of binary functions II");
	show("[lambda (x,y) if (x=y) then x else y end, join]");
	show("[lambda (x,y) if (x=y) then x else y end, sum]");
	show("[lambda (x,y) if (x=y) then x else y end, multiply]");
	show("[lambda (x,y) if (x=y) then x else y end, join, sum]");
	show("[lambda (x,y) if (x=y) then x else y end, join, multiply]");
	show("[lambda (x,y) if (x=y) then x else y end, sum, multiply]");
	show("[lambda (x,y) if (x=y) then x else y end, join, sum, multiply]");
	
}

public void demo7() {
  ep(
"let powers(list) = reduceList([[]],
							  lambda(x) [x],
	 						  lambda(powers,x)
	 						    append([append(a,x) | a in powers], powers),
	 						  list) in
  powers([1,2,3])
end");
}

public void fm () {
	ep(
"let flow = backward-forward in
   let first (x,y) = x in
     let second (x,y) = y in
       let empty = head([j| i,j from head(columns(flow))]) in
         let rows = {i | i,j from flow} in
           let abs(x) = sum[if v leq 0 then -v else v end | i,j from x, v := isolate(x,i,j)] in
             let cols = columns(flow) in
	           let idents = columns(rightIdentity(flow)) in
	             let pairs = zip(cols,idents) in
                   let eliminate(row, pairs) =
                     [scale(abs(alpha),ww) |
                     (*[scale(abs(beta),vv) + scale(abs(alpha),ww) |*)
  					  x in pairs, y in pairs,
  					  v := apply(first,x), w := apply(first,y),
  					  vv := apply(second,x), ww := apply(second,y),
  					  alpha := magnitude(v,row,empty), 
  					  beta := magnitude(w,row,empty),
  					  alpha*beta leq 0 (*,
  					  not (alpha*beta = 0)*)]
  				   in
                     head([eliminate(r, pairs) | r elt rows])
                   end
		         end
		       end
		     end
		   end
		 end
	   end
     end
   end
 end");
}

//[apply(second, x) | x in zip(cols,idents)]

public void show (str exp) {
	try {
		parsed = parseImplodePacioli(exp);
		<typ, _> = inferTypeAPI(parsed, env());
		//println("<exp> :: <pprint(typ)>");
		println("<exp> :: <pprint(unfresh(typ))>");
	} catch err: {
		println(err);
	}	
}



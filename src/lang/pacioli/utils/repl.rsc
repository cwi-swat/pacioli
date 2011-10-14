module lang::pacioli::utils::repl

import List;
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
//str glbCasesDirectory = "D:/code/cwi/pacioli/cases/";

str prelude() = "baseunit dollar \"$\";
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
			  'entity Conspiracy \"<glbCasesDirectory>case4/conspiracy.entity\";
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
	 "basis":              "case4/basis.csv",
	 "isAsset":            "case4/isAsset.csv",
	 "isLegit":            "case4/isLegit.csv",
	 "isJournal":          "case4/isJournal.csv",
	 "owner":              "case5/owner.csv",
	 "parent":             "case5/parent.csv",
	 "fileSize":           "case5/fileSize.csv",
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
	SimpleEntity Conspiracy = simple("Conspiracy");
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
   "basis": forall({},{},{}, matrix(uno(), duo(compound([Transition]), uno()), duo(compound([Conspiracy]), uno()))),
   "isAsset": forall({},{},{}, matrix(uno(), empty, duo(compound([Place]), uno()))),
   "isLegit": forall({},{},{}, matrix(uno(), duo(compound([Transition]), uno()), empty)),
   "isJournal": forall({},{},{}, matrix(uno(), empty, duo(compound([Place]), uno()))),
   "owner": forall({},{},{}, matrix(uno(),duo(compound([File]), uno()), duo(compound([Module]), uno()))),
   "parent": forall({},{},{}, matrix(uno(),duo(compound([Module]), uno()), duo(compound([Module]), uno()))),
   "lines": forall({},{},{}, matrix(linesOfCode,empty, duo(compound([File]), uno()))),
   "fileSize": forall({},{},{}, matrix(byte,empty, duo(compound([File]), uno()))),
   "root": forall({},{},{}, matrix(uno(), duo(compound([Module]), uno()),empty)),
   "emptyList": forall({},{},{"a"},listType(typeVar("a"))),   
   "empty": forall({},{},{}, entity(compound([]))),
   "matrixFromTuples": forall({"a"},{"P", "Q"},{},
  				  function(tupType([setType(tupType([entity(entityVar("P")),
  				                                      entity(entityVar("Q")),
  				                                      matrix(unitVar("a"), empty, empty)]))]),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), uno()),
  				  				  duo(entityVar("Q"), uno())))),
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
	"unitFactor": forall({"a", "b", "u", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  					   duo(entityVar("P"), unitVar("u")),
  				  					   duo(entityVar("Q"), unitVar("v")))]),
				           matrix(unitVar("a"), empty, empty))),
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
	"size": forall({},{},{"a"},
  				  function(tupType([listType(typeVar("a"))]),
				           matrix(uno(), empty, empty))),
	"div": forall({},{},{},
  				  function(tupType([matrix(uno(), empty, empty),matrix(uno(), empty, empty)]),
				           matrix(uno(), empty, empty))),  				  				  
	"mod": forall({},{},{},
  				  function(tupType([matrix(uno(), empty, empty),matrix(uno(), empty, empty)]),
				           matrix(uno(), empty, empty))),  				  				  
	"gcd": forall({},{},{},
  				  function(tupType([matrix(uno(), empty, empty),matrix(uno(), empty, empty)]),
				           matrix(uno(), empty, empty))),  				  				  
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
	"less": forall({"a", "u", "v"},{"P", "Q"},{},
				function(tupType([matrix(unitVar("a"), 
  				  					 duo(entityVar("P"), unitVar("u")),
  				  					 duo(entityVar("Q"), unitVar("v"))),
  				  			  matrix(unitVar("a"), 
  				  					 duo(entityVar("P"), unitVar("u")),
  				  					 duo(entityVar("Q"), unitVar("v")))]),
				         boolean())),				         
	"indexLess": forall({},{"P"},{},
				function(tupType([entity(entityVar("P")), entity(entityVar("P"))]),
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
	"rowIndex": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v")))]),
				           matrix(uno(), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  empty))),
	"columnIndex": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v")))]),
				           matrix(uno(),
  				  				  duo(entityVar("Q"), unitVar("v")), 
				           		  empty))),  				  				  
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
	"print": forall({},{},{"a"},
  				  function(tupType([typeVar("a")]), typeVar("a"))),  				  
  	"true": forall({},{},{}, boolean()),
  	"false": forall({},{},{}, boolean()),
  	"not": forall({},{},{},
  				  function(tupType([boolean()]), boolean())),
  	"apply": forall({},{},{"a", "b"},
  				  function(tupType([function(typeVar("a"), typeVar("b")),
  				  					typeVar("a")]), 
  				  		   typeVar("b"))),
	"tuple": forall({},{},{"a"}, function(typeVar("a"), typeVar("a"))),
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
	"loopList": forall({},{},{"a", "b", "c"},
  				  function(tupType([typeVar("b"),
  				  					function(tupType([typeVar("b"), typeVar("c")]), typeVar("b")),
  									listType(typeVar("c"))]), 
  				  		   typeVar("b"))),  				  		     				  		   
	"reduceSet": forall({},{},{"a", "b", "c"},
  				  function(tupType([typeVar("c"),
  				  					function(tupType([typeVar("a")]), typeVar("b")),
  				  					function(tupType([typeVar("c"), typeVar("b")]), typeVar("c")),
  									setType(typeVar("a"))]), 
  				  		   typeVar("c"))),  				  		   
  	"reduceMatrix": forall({"a", "u", "v"},{"P", "Q"},{"b", "c"},
		function(tupType([typeVar("c"),
  					      function(tupType([entity(entityVar("P")), entity(entityVar("Q"))]),
  				  			 	   typeVar("b")),
  						  function(tupType([typeVar("c"), typeVar("b")]), typeVar("c")),
						  matrix(unitVar("a"), 
  				  				 duo(entityVar("P"), unitVar("u")),
  				  				 duo(entityVar("Q"), unitVar("v")))]), 
  		   		 typeVar("c"))),
	"loopMatrix": forall({"a", "u", "v"},{"P", "Q"},{"b", "c"},
		function(tupType([typeVar("c"),
  						  function(tupType([typeVar("c"), entity(entityVar("P")), entity(entityVar("Q"))]), typeVar("c")),
						  matrix(unitVar("a"), 
  				  				 duo(entityVar("P"), unitVar("u")),
  				  				 duo(entityVar("Q"), unitVar("v")))]), 
  		   		 typeVar("c"))),  		   		 
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
	"addMut": forall({},{},{"a"},
  				  function(tupType([listType(typeVar("a")),typeVar("a")]), listType(typeVar("a")))),
	"adjoinMut": forall({},{},{"a"},
  				  function(tupType([setType(typeVar("a")),typeVar("a")]), setType(typeVar("a")))),
	"row": forall({"a", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  				           duo(entityVar("P"), uno()),
  				  				           duo(entityVar("Q"), unitVar("v"))),
  				  				    entity(entityVar("P"))]),
				           matrix(unitVar("a"),
  				  				  empty, 
  				  				  duo(entityVar("Q"), unitVar("v"))))),
	"column": forall({"a", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  				           duo(entityVar("P"), unitVar("v")),
  				  				           duo(entityVar("Q"), uno())),
  				  				    entity(entityVar("Q"))]),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("v")),
  				  				  empty))),
	"columnDomain": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  					       duo(entityVar("P"), unitVar("u")),
  				  					       duo(entityVar("Q"), unitVar("v")))]),
				           listType(entity(entityVar("Q"))))),
	"rowDomain": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(tupType([matrix(unitVar("a"), 
  				  					       duo(entityVar("P"), unitVar("u")),
  				  					       duo(entityVar("Q"), unitVar("v")))]),
				           listType(entity(entityVar("P"))))));
}

////////////////////////////////////////////////////////////////////////////////
// Repl utilities

public str addLoads(str prelude, Environment env) {
	text = prelude;
	for (name <- env) {
		if (forall({},{},{},matrix(f,r,c)) := env[name] && name in fileLoc) {
			text = text + ";\nload <name> \"<glbCasesDirectory><fileLoc[name]>\" \"<serial(f)>\" \"<serial(r)>\" \"<serial(c)>\"";
		}
	}
	return text;
}

public str addEvals(str prelude, Repo repo) {
	text = prelude;
	// Two passes to support some dependencies
	for (name <- glbReplRepoOrder) {
		<code,sch> = repo[name];
		if (isFunction(sch)) {
			text += ";\neval <name> <compilePacioli(code)>";
		}
	}
	for (name <- glbReplRepoOrder) {
		<code,sch> = repo[name];
		if (!isFunction(sch)) {
			text += ";\neval <name> <compilePacioli(code)>";
		}
	}
	return text;
}		
////////////////////////////////////////////////////////////////////////////////
// The repl
			  
alias Repo = map[str,tuple[Expression,Scheme]];
  			  
Repo glbReplRepo = ();
list[str] glbReplRepoOrder = [];

public bool isFunction(forall(_,_,_, Type t)) {
	switch (t) {
	case function(_,_): return true;
	default: return false;
	}
}

public void ls () {
	Environment env = env();
	for (name <- env) {
		if (!isFunction(env[name])) {
			println("<name> :: <pprint(env[name])>");
		}
	}
	for (name <- glbReplRepo) {
		<code,sch> = glbReplRepo[name];
		if (!isFunction(sch)) {
			println("<name> :: <pprint(sch)>");
		}
	}
}

public void functions () {
	Environment env = env();
	for (name <- env) {
		if (isFunction(env[name])) {
			println("<name> :: <pprint(env[name])>");
		}
	}
	for (name <- glbReplRepo) {
		<code,sch> = glbReplRepo[name];
		if (isFunction(sch)) {
			println("<name> :: <pprint(sch)>");
		}
	}
}

public void parse (str exp) {
	parsed = parseImplodePacioli(exp);
	println(pprint(parsed));
	println(parsed);
}

public void compile(Expression exp) {
	try {
		//stdLib();
	
		fullEnv = env();
		
		header = addLoads(prelude(),fullEnv);
		header = addEvals(header,glbReplRepo);
		for (name <- glbReplRepo) {
			<code,sch> = glbReplRepo[name];
			fullEnv += (name:sch);
		}
		
		<typ, _> = inferTypeAPI(exp, fullEnv);
		ty = unfresh(typ);
		scheme = forall(unitVariables(ty),
				        entityVariables(ty),
				        typeVariables(ty),
				        ty);
		println("<pprint(exp)>\n  :: <pprint(scheme)>");
		code = compilePacioli(exp);
		prog = "<header>;
		   	   'eval result <code>; 
	       	   'print result";		
		writeFile(|project://pacioli/cases/tmp.mvm|, [prog]);
	} catch err: {
		println(err);
	}
}

public void compile(str exp) {
	try {
		fullEnv = env();
		header = addLoads(prelude(),fullEnv);
		header = addEvals(header,glbReplRepo);
		
		//// Two passes to support some dependencies
		//for (name <- glbReplRepo) {
		//	<code,sch> = glbReplRepo[name];
		//	if (isFunction(sch)) {
		//		fullEnv += (name:sch);
		//		header += ";\neval <name> <compilePacioli(code)>";
		//	}
		//}
		//for (name <- glbReplRepo) {
		//	<code,sch> = glbReplRepo[name];
		//	if (!isFunction(sch)) {
		//		fullEnv += (name:sch);
		//		header += ";\neval <name> <compilePacioli(code)>";
		//	}
		//}
		for (name <- glbReplRepo) {
			<code,sch> = glbReplRepo[name];
			fullEnv += (name:sch);
		}
		
		parsed = parseImplodePacioli(exp);
		<typ, _> = inferTypeAPI(parsed, fullEnv);
		ty = unfresh(typ);
		scheme = forall(unitVariables(ty),
				        entityVariables(ty),
				        typeVariables(ty),
				        ty);
		println("<exp>\n  :: <pprint(scheme)>");
		code = compilePacioli(parsed);
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
		full = parsed;
		fullEnv = env();
		for (n <- glbReplRepo) {
			<code,sch> = glbReplRepo[n];
			fullEnv += (n:sch);
		}
		// hack for recursive functions
		f = fresh("def");
		fullEnv += (name: forall({},{},{},typeVar(f)));
		
		<typ, s> = inferTypeAPI(full, fullEnv);
		typ = unfresh(typ);
 		// to make sure it compiles later on		
		compilePacioli(full);
		scheme = forall(unitVariables(typ),
				entityVariables(typ),
				typeVariables(typ),
				typ);

		glbReplRepo += (name: <parsed,scheme>);
		glbReplRepoOrder -= name;
		glbReplRepoOrder += name;
		println("<name> :: <pprint(scheme)>");
	} catch err: {
		println(err);
	}
}

public void compileFile (str name) {
	stdLib();
	lines = readFile(name);
	if (lines == []) return;
	exp = (head(lines) | it + "\n" + x  | x <- tail(lines));
	return compile(exp);
}

public void dump(str exp, str entityFile, str matrixFile) {
	try {
		fullEnv = env();
		header = addLoads(prelude(),fullEnv);
		for (name <- glbReplRepo) {
			<code,sch> = glbReplRepo[name];
			fullEnv += (name:sch);
			header += ";\neval <name> <compilePacioli(code)>";
		}
		parsed = parseImplodePacioli(exp);
		<typ, _> = inferTypeAPI(parsed, fullEnv);
		println("<exp> :: <pprint(unfresh(typ))>");
		code = compilePacioli(parsed);
		prog = "<header>;
		   	   'eval result <code>; 
	       	   'dump result \"<entityFile>\" \"<matrixFile>\"";		
		writeFile(|file:///<glbCasesDirectory>tmp.mvm|, [prog]);
	} catch err: {
		println(err);
	}
}

int glbcounter = 100;

str fresh(str x) {glbcounter += 1; return "<x><glbcounter>";}

////////////////////////////////////////////////////////////////////////////////
// Demos
public void demo0() {
	def("f", "lambda (x) x*x");
	compile("f(2)");
}

public void demo1() {

	println("\nBase units are pre-defined");
	compile("gram");
	compile("metre");
	
	println("\nUnits can always be multiplied");
	compile("gram * gram");
	compile("gram * metre");
	
	println("\nUnits can not always be summed");
	compile("gram + gram");
	println("\ngram + metre gives an error:");
	compile("gram + metre");
	
	println("\nThe type is semantic, the order of multiplication is irrelevant");
	compile("gram*metre + gram*metre");
	compile("gram*metre + metre*gram");
	
	println("\nThe type system does inference.");
	compile("lambda (x) x*metre + gram*metre");
	
	println("\nThe type system derives a most general type."); 
	compile("lambda (x,y) x*y + gram*metre");
	compile("(lambda (x) lambda (y) x*y + gram*metre) (gram)");
	compile("(lambda (x,y) x*y + gram*metre)(gram,metre)");
	compile("(lambda (x,y) x*y + gram*metre)(metre,gram)");
	
	println("\nMultiplying left and right is not allowed. A multiplication and division cancel");
	println("\n(lambda (x,y) x*y + gram*metre)(metre*second,gram*second) gives an error:"); 
	compile("(lambda (x,y) x*y + gram*metre)(metre*second,gram*second)");
	compile("(lambda (x,y) x*y + gram*metre)(metre*second,gram/second)");
}
	
public void demo2() {
	
	// General
	compile("lambda(x) x.x");
	compile("lambda(x) x+x+x+x");
	compile("lambda(x) (x+x)*(x+x)");
	compile("lambda(x,y) (x-y).(y-x)");
	
	// Norm
	compile("lambda(x) total(x*x)");
	compile("lambda(x) sqrt(total(x*x))");
	
	// Lie algebras
	compile("lambda(x,y) x.y-y.x");
	
	// Netting problem
	compile("lambda(x) bom.x");
	compile("(lambda(x) x . output) (conv . bom . conv^R^T)");
	compile("(lambda(x) closure(x)) (conv.bom.conv^R^T)");
	compile("(lambda(x) closure(x) . output) (conv . bom . conv^R^T)");
	compile("(lambda(f) closure(f(bom)) . output) (lambda (x) conv . x . conv^R^T)");
	
	// Salesdata
	compile("sales / amount^T");
	compile("(lambda(price) (price . P2^R^T) * (price . P2^R^T)) (sales / amount^T)");
	compile("(lambda(price) price.P2^R^T * price.P2^R^T) (sales / amount^T)");
	compile("(lambda(price) (price . P2^R^T)) (sales / amount^T)");
	compile("(lambda(price) price.P2^R^T) (sales / amount^T)");
	compile("sales.P1 / P2.amount");
	
	// Restaurant
	compile("menu_price . menu_sales");
	compile("menu_price * menu_sales^T");
}

public void demo3() {
	
	stdLib();
	
	println("\nThe quantities involved");
	compile("backward");
	compile("forward");
	compile("backward-forward");
	compile("valuation");
	compile("valuation.(backward-forward)");
		
	println("\nSome comprehensions");
	compile("columns(backward-forward)");
	compile("[x | x in columns(backward-forward)]");
	compile("[x | x in columns(backward-forward), not(valuation.x = 0)]");
	compile("count[x | x in columns(backward-forward)]");
	compile("count[x | x in columns(backward-forward), not(valuation.x = 0)]");
	compile("[val | x in columns(backward-forward), val := valuation.x, not(val = 0)]");
	compile("sum[x | x in columns(backward-forward), not(valuation.x = 0)]");
	compile("valuation . sum[x | x in columns(backward-forward), not(valuation.x = 0)]");
	
	println("\nSome abstractions");
	compile("lambda (a) a . sum[x | x in columns(backward-forward), not(valuation.x = 0)]");
	compile("lambda (a) valuation . sum[x | x in columns(a-forward), not(valuation.x = 0)]");
	compile("(lambda (a) valuation . sum[x | x in columns(a-forward), not(valuation.x = 0)])(backward)");
	compile("(lambda (a) valuation . sum[x | x in columns(a-forward), not(valuation.x = 0)])(forward)");
}

public void demo4() {

	println("\nQuantities");
	compile("lines");
	compile("fileSize");
	compile("owner");
	compile("parent");

	println("\nAggregations");
	compile("fileSize.owner");
	compile("fileSize.owner.parent");
	compile("fileSize.owner.parent*");
	
	println("\nComprehensions");
	compile("[x | x in columns(owner), not(x=0)]");
	compile("[lines.x | x in columns(owner), not(x=0)]");
	compile("[fileSize.x/lines.x | x in columns(owner), not(x=0)]");
	compile("[total(x) | x in columns(owner), x=0]");
	compile("[t | x in columns(owner), t := total(x), t=0]");
	compile("count[t | x in columns(owner), t := total(x), t=0]");
	
	println("\nAggregation functions.");
	compile("lambda (x) x.owner.parent*");
	compile("let agg(x) = x.owner.parent* in agg(lines) end");
	//compile("(lambda (agg) agg(fileSize)/agg(lines)) (lambda (x) x.owner.parent*)");
	compile("let agg(x) = x.owner.parent* in agg(fileSize)/agg(lines) end");
	
}

public void demo5() {
	compile(
"let dice = [1,2,3,4,5,6] in
   let sums = [x+y | x in dice, y in dice] in
     let total = count[s | s in sums] in
	   let cnt(n) = count[s | s in sums, s=n] in
	     [tuple(i,cnt(i)/total) | i elt {x+y | x in dice, y in dice}]
	   end
	 end
   end
 end");
}

public void demo6() {
	
	println("Some fun with lattices I");
	compile("[negative]");
	compile("[transpose]");
	compile("[reciprocal]");
	compile("[negative, transpose]");
	compile("[negative, reciprocal]");
	compile("[transpose, reciprocal]");
	compile("[negative, transpose, reciprocal]");
	
	println("Some fun with lattices II");
	compile("[identity, negative]");
	compile("[identity, transpose]");
	compile("[identity, reciprocal]");
	compile("[identity, negative, transpose]");
	compile("[identity, negative, reciprocal]");
	compile("[identity, transpose, reciprocal]");
	compile("[identity, negative, transpose, reciprocal]");
	
	println("Some fun with lattices of binary functions I");
	compile("[join]");
	compile("[sum]");
	compile("[multiply]");
	compile("[join, sum]");
	compile("[join, multiply]");
	compile("[sum, multiply]");
	compile("[join, sum, multiply]");
	
	println("Some fun with lattices of binary functions II");
	compile("[lambda (x,y) if (x=y) then x else y end, join]");
	compile("[lambda (x,y) if (x=y) then x else y end, sum]");
	compile("[lambda (x,y) if (x=y) then x else y end, multiply]");
	compile("[lambda (x,y) if (x=y) then x else y end, join, sum]");
	compile("[lambda (x,y) if (x=y) then x else y end, join, multiply]");
	compile("[lambda (x,y) if (x=y) then x else y end, sum, multiply]");
	compile("[lambda (x,y) if (x=y) then x else y end, join, sum, multiply]");
	
}

public void demo7() {
  compile(
"let powers(list) = reduceList([[]],
							  lambda(x) [x],
	 						  lambda(powers,x)
	 						    append([append(a,x) | a in powers], powers),
	 						  list) in
  let combis(list) = apply(lambda (x,y) x,
                           reduceList(tuple([],list),
							  lambda(x) x,
	 						  lambda(accu,x)
	 						    apply(lambda (a,b) tuple(append([tuple(x,y) | y in tail(b)],a),tail(b)),accu),
	 						  list)) in
  combis([1,2,3])
  end
end");
}

public void demo8(){
	compile(
"let gcd(x,y) = if x=0 then
				  y
				else
				  if y = 0 then
				    x
				  else 
				    if x leq y then
				      gcd(x,y-x)
				    else
				      gcd(x-y,y)
				    end
				  end
				end
 in
   let f(x,y) = gcd(x,y) in
   	  let a = f in a(163,264) end
   	end 
 end");
}

public void demo9() {
	compile("let nums = [0,1,2,3,4,5] in
	           let a = [[x,y] | x in nums, y in nums] in
	             let b = [[x,y] | x in a, y in a] in
	               let c = [[x,y] | x in b, y in b] in
	                 size(c)
	               end
	             end
	           end
	         end");
}

public void test9() {
	nums = [0,1,2,3,4,5];
	a = [[x,y] | x <- nums, y <- nums];
	b = [[x,y] | x <- a, y <- a];
	c = [[x,y] | x <- b, y <- b];
	println(size(c));
}

public void demo10() {
	println("Functions and tuples in Pacioli");
	compile("apply");
	compile("tuple");
	compile("identity");
}

public void fm() {
	stdLib();
	def("eliminate", "lambda(quadruples, row)
                       let combined = [tuple(scaled1, support(scaled1), scaled2, support(scaled2)) |
                                         (v,w) in combis(quadruples),
                                         (v1,sv1,v2,sv2) := v,
                                         (w1,sw1,w2,sw2) := w,
  					                     alpha := magnitude(v1,row,empty), 
  					                     beta := magnitude(w1,row,empty),
  					                     alpha*beta \< 0,
  					                     scaled1 := scale(abs(beta),v1) + scale(abs(alpha),w1),
  					                     scaled2 := scale(abs(beta),v2) + scale(abs(alpha),w2)]
  					   in
  					     [q | q in append(combined, quadruples),
  					            (v1, support1, v2, support2) := q,
  					            magnitude(v1, row, empty) = 0]
  					   end");  					    
	def("canonical", "lambda (quadruple)
	                    let (v1, support1, v2, support2) = quadruple in
                          let c = 1 / gcd(gcd[magnitude(v1,i,j) | i,j from v1],
                                          gcd[magnitude(v2,i,j) | i,j from v2]) in
                            tuple(scale(c,v1), support1, scale(c,v2), support2)
                          end
                        end");                
	def("filterMinimals", "lambda (quadruples)
                             [q | q in quadruples,
                                  (q1,sq1,q2,sq2) := q,
                                  all[not(sr1 \<= sq1 && sr2 \<= sq2) || (sq1 = sr1 && sq2 = sr2) |
		                                (r1,sr1,r2,sr2) in quadruples]]");
	def("filterMinimalsNested", "lambda (quadruples)
                             [q | q in quadruples,
                                  (q1,sq1,q2,sq2) := q,
                                  all[sq1 = sr1 && sq2 = sr2 |
		                                (r1,sr1,r2,sr2) in quadruples,
		                                sr1 \<= sq1 && sr2 \<= sq2]]");
    def("fourierMotzkin", "lambda (matrix)
                             [v2 | (v1, support1, v2, support2) in 
                                     loopList([tuple(v1, support(v1), v2, support(v2)) |
	                                                 (v1,v2) in zip(columns(matrix), columns(rightIdentity(matrix)))],
                                              lambda(quadruples, row)
										        filterMinimals([canonical(v) | v in eliminate(quadruples, row)]),
                                 			  rowDomain(matrix))]");
	dump("fourierMotzkin(backward-forward)",
	     "/home/paul/data/code/cwi/pacioli/cases/case4/conspiracy.entity",
	     "/home/paul/data/code/cwi/pacioli/cases/case4/basis.csv");
}

public void stdLib() {
	def("combis", "lambda (list) 
		             let (result, dummy) = loopList(tuple([],list),
							                        lambda(accu,x)
							                          let (result,tails) = accu in
	 						                            tuple(append([tuple(x,y) | y in list tail(tails)], result), tail(tails))
	 						                          end,
	 						                        list) in
	 		           result
	 		         end");
	def("columns", "lambda (matrix) [column(matrix,j) | j in list columnDomain(matrix)]");
	def("rows", "lambda (matrix) [row(matrix,i) | i in list rowDomain(matrix)]");
	def("magnitudeMatrix", "lambda (mat) \<i,j -\> magnitude(mat,i,j) | i,j in matrix mat\>");
	def("unitMatrix", "lambda (mat) scale(unitFactor(mat), rowIndex(mat) per columnIndex(mat))");
	def("support", "lambda (x) \<i,j -\> 1 | i,j in matrix x, 0 \< magnitude(x,i,j)\>");
	def("leftIdentity", "lambda (x) \<i,i -\> 1 | i in list rowDomain(x)\> * (rowIndex(x) per rowIndex(x))");
	def("rightIdentity", "lambda (x) \<j,j -\> 1 | j in list columnDomain(x)\> * (columnIndex(x) per columnIndex(x))");
}

public void fmAnalysis() {
	stdLib();
	def("flow", "backward-forward");
	def("leftBang", "lambda (matrix) sum[c | c in columns(support(leftIdentity(matrix)))]");
	def("rightBang", "lambda (matrix) sum[r | r in rows(support(rightIdentity(matrix)))]");
	def("isReal", "rightBang(isJournal)-isJournal");
	def("isLiability", "rightBang(isAsset)-isAsset");
	def("isIllicit", "leftBang(isLegit)-isLegit");
	def("value", "valuation*(isAsset-isLiability)");
	def("legitProduction", "lambda (t) flow.(t*isLegit)");
	def("illicitProduction", "lambda (t) flow.(t*isIllicit)");
	compile("[tuple(con,illVal, legVal) |
	            con in columnDomain(basis),
	            t := column(basis,con),
	            illVal := value.illicitProduction(t),
	            legVal := value.legitProduction(t), 
	            0 \< illVal]");
	//compile("[j | j in columnDomain(basis), col := column(basis,j), not(flow.col = 0)]");
}


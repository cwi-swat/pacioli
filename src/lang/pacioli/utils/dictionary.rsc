module lang::pacioli::utils::dictionary

import List;
import Map;

import units::units;

import lang::pacioli::types::inference;
import lang::pacioli::types::Types;

////////////////////////////////////////////////////////////////////////////////
// Hardwired Data Schema 

public str glbCasesDirectory = "/home/paul/data/code/cwi/pacioli/cases/";
//str glbCasesDirectory = "D:/code/cwi/pacioli/cases/";

public str prelude() = "baseunit dollar \"$\";
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
			  'projection P0 \"Commodity,Year,Region!1\" \"Commodity!1\";
			  'projection P1 \"Commodity,Year,Region!1\" \"Commodity,Year!1\";
			  'projection P2 \"Year,Commodity!1,unit\" \"Commodity,Year,Region!unit,1,1\";
			  'entity Place \"<glbCasesDirectory>case4/place.entity\";
			  'entity Transition \"<glbCasesDirectory>case4/transition.entity\";
			  'index Place unit \"<glbCasesDirectory>case4/place.unit\";
			  'entity Conspiracy \"<glbCasesDirectory>case4/conspiracy.entity\";
			  'entity File \"<glbCasesDirectory>case5/file.entity\";
			  'entity Module \"<glbCasesDirectory>case5/module.entity\"";


public map[str,str] fileLoc = 
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
   "zero": forall({},{},{}, entity(compound([]))),
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
	"listSize": forall({},{},{"a"},
  				  function(tupType([listType(typeVar("a"))]),
				           matrix(uno(), empty, empty))),
	"setSize": forall({},{},{"a"},
  				  function(tupType([setType(typeVar("a"))]),
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

	 
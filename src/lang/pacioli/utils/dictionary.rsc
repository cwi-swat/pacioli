module lang::pacioli::utils::dictionary

import List;
import Map;

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
			  'projection P2 \"Commodity,Year!unit,1\" \"Commodity,Year,Region!unit,1,1\";
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

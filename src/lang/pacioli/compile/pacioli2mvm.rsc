module lang::pacioli::compile::pacioli2mvm

import units::units;
import units::unification;
import lang::pacioli::ast::KernelPacioli;
import lang::pacioli::utils::Implode;
import lang::pacioli::types::Types;
import IO;

alias Register = map[str var, str register];

public str compilePacioli(Expression exp) {
	dir = 
	prelude = "baseunit dollar \"$\";
			  'baseunit euro \"€\";
			  'unit litre \"l\" (deci metre)^3;
			  'unit pound \"lb\" 0.45359237*kilo gram;
			  'unit ounce \"oz\" pound/16;
			  'unit barrel \"bbl\" 117.347765*litre;
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
	          'entity Product \"case1/product.entity\";
			  'index Product bom_unit \"case1/product.bom_unit\";
			  'index Product trade_unit \"case1/product.trade_unit\";
			  'conversion conv \"Product\" \"bom_unit\" \"trade_unit\";
			  'load output \"case1/output.csv\" \"1\" \"Product.trade_unit\" \"empty\";
			  'load purchase_price \"case1/purchase_price.csv\" \"euro\" \"empty\" \"Product.trade_unit\";
			  'load sales_price \"case1/sales_price.csv\" \"euro\" \"empty\" \"Product.trade_unit\";
			  'load bom \"case1/bom.csv\" \"1\" \"Product.bom_unit\" \"Product.bom_unit\";
			  'entity Commodity \"case2/commodity.entity\";
			  'entity Year \"case2/year.entity\";
			  'entity Region \"case2/region.entity\";
			  'index Commodity unit \"case2/commodity.unit\";
			  'load sales \"case2/sales.csv\" \"dollar\" \"empty\" \"Commodity,Year,Region.1\";
			  'load amount \"case2/amount.csv\" \"1\" \"Commodity,Year,Region.unit,1,1\" \"empty\";
			  'projection P0 \"Commodity,Year,Region.1\" \"Commodity.1\";
			  'projection P1 \"Commodity,Year,Region.1\" \"Commodity,Year.1\";
			  'projection P2 \"Year,Commodity.1,unit\" \"Commodity,Year,Region.unit,1,1\";
			  'entity Ingredient \"case3/ingredient.entity\";
			  'entity Menu \"case3/menu.entity\";
			  'index Ingredient unit \"case3/ingredient.unit\";
			  'load semi_bom \"case3/semi_bom.csv\" \"1\" \"Ingredient.unit\" \"Menu.1\";
			  'load ingredient_price \"case3/ingredient_price.csv\" \"dollar\" \"empty\" \"Ingredient.unit\";
			  'load menu_sales \"case3/menu_sales.csv\" \"1\" \"Menu.1\" \"empty\";
			  'load menu_price \"case3/menu_price.csv\" \"dollar\" \"empty\" \"Menu.1\"";
	<code,reg> = compileExpression(exp,());
	prog = "<prelude>;
		   '<code>; 
	       'print <reg>";
	return prog;
}

public tuple[str,str] compileExpression(Expression exp, Register reg) {
	switch (exp) {
		case variable(x): {
			return <"skip", (x in reg) ? reg[x] : x>; 
		}
		case application(abstraction(var,body),arg): {
			<c1,r1> = compileExpression(arg,reg);
			<c2,r2> = compileExpression(body,reg+(var:r1));
			return <"<c1>;\n<c2>", r2>;
		}
		case application(variable(fn),pair2(a,b)): {
			<c1,r1> = compileExpression(a,reg);
			<c2,r2> = compileExpression(b,reg);
			r = fresh("r");
			return <"<c1>;\n<c2>;\n<fn> <r> <r1> <r2>", r>;
		}
		case application(variable(fn),arg): {
			<c1,r1> = compileExpression(arg,reg);
			r = fresh("r");
			return <"<c1>;\n<fn> <r> <r1>", r>;
		}
		default: throw("Functions and pairs as values not (yet) supported");
	}
}

public void showGen (str exp) {
	try {
		glbcounter = 0;
		parsed = parseImplodePacioli(exp);
		code = compilePacioli(parsed);
		println(code);
	} catch err: {
		println(err);
	}
}

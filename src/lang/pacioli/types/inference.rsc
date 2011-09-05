module lang::pacioli::types::inference

import Map;
import Set;
import List;
import IO;

import units::units;
import units::unification;

import lang::pacioli::ast::KernelPacioli;
import lang::pacioli::utils::Implode;
import lang::pacioli::types::Types;
import lang::pacioli::types::unification;


alias Environment = map[str, Scheme];

public Environment envSubs(Substitution s, Environment e) {
	return (key: schemeSubs(s, e[key]) | key <- e);
}

public Scheme schemeSubs(substitution(ub, eb, tb),
						 forall(unitVars, entityVars, typeVars, typ)) {
	return forall(unitVars, entityVars, typeVars,
				  typeSubs(substitution(
				  			(key: ub[key] | key <- ub, !(key in unitVars)),
					        (key: eb[key] | key <- eb, !(key in entityVars)),
					        (key: tb[key] | key <- tb, !(key in typeVars))),
					       typ)); 
}

public Type instScheme(forall(unitVars, entityVars, typeVars, typ)) {
	EntityBinding eb = (x: entityVar(fresh("E")) | x <- entityVars);
	UnitBinding ub = (x: unitVar(fresh("u")) | x <- unitVars);
	TypeBinding tb = (x: typeVar(fresh("t")) | x <- typeVars);
	return typeSubs(substitution(ub,eb,tb), typ);
}


public list[str] glbstack = [];
public str glberror = "so far, so good";

public tuple[Type, Substitution] inferType(Expression exp, Environment assumptions) {
	push("<pprint(exp)>");
	switch (exp) {
		case variable(x): {
			typ = instScheme(assumptions[x]);
			pop("<pprint(typ)>");
			return <typ, ident>;
		}
		case pair2(x,y): {
			<t1, s1> = inferType(x, assumptions);
			<t2, s2> = inferType(y, envSubs(s1, assumptions));
			typ = typeSubs(s2, pair(t1, t2));
			pop("<pprint(typ)>");
			return <typ, merge(s1,s2)>;
		}
		case application(x,y): {
			<funType, s1> = inferType(x, assumptions);
			<argType, s2> = inferType(y, envSubs(s1, assumptions));
			s12 = merge(s1,s2);
			beta = fresh("identifier");
			template = function(argType, typeVar(beta));
			<succ, s3> = unifyTypes(typeSubs(s2, funType), template, s12);
			if (succ) {
				s123 = merge(s12,s3);
				typ = typeSubs(s123, typeVar(beta));
				pop("<pprint(typ)>");
				return <typ, s123>;
			} else {
				throw("\nType error: <glberror>\n\nStack:<("" | "<it>\n<frame>" | frame <- glbstack)>");
			}
		}
		case abstraction(x,b): {
			beta = fresh(x);
			<t1, s1> = inferType(b, assumptions+(x: forall({},{},{},typeVar(beta))));
			typ = typeSubs(s1,function(typeVar(beta), t1));
			pop("<pprint(typ)>");
			return <typ, s1>;
		}
	}
}

public void push(str log) {
	glbstack = [log] + glbstack;
	n = size(glbstack)-1; 
	//println("<filler(n)><n>\> <head(glbstack)>");
}

public void pop(str log) {
	n = size(glbstack)-1;
	//println("<filler(n)><n>\< <log>");
	glbstack = tail(glbstack); 
}

public str filler(int n) = (n==0) ? "" : ("" | it + " " | _ <- [1..n]); 


////////////////////////////////////////////////////////////////////////////////
// Tests

public Environment env() {

	Unit gram = named("g", self());
	Unit metre = named("m", self());
	Unit second = named("s", self());
	Unit dollar = named("$", self());

	IndexType empty = duo(compound([]), uno());
	
	EntityType Product = compound([simple("Product")]);
	Unit tradeUnit = named("trade_unit", self());
	Unit bomUnit = named("bom_unit", self());
	
	IndexType tradeIndex = duo(Product, tradeUnit);
	IndexType bomIndex = duo(Product, bomUnit);
	
	SimpleEntity Commodity = simple("Commodity");
	SimpleEntity Year = simple("Year");
	SimpleEntity Region = simple("Region");
	Unit commodityUnit = named("unit", self());


  return (
   "gram": forall({},{},{}, matrix(gram, empty, empty)),
   "metre": forall({},{},{}, matrix(metre, empty, empty)),
   "second": forall({},{},{}, matrix(second, empty, empty)),
   "dollar": forall({},{},{}, matrix(dollar, empty, empty)),
   "bom": forall({},{},{}, matrix(uno(), bomIndex, bomIndex)),
   "conv": forall({},{},{}, matrix(uno(), tradeIndex, bomIndex)),
   "output": forall({},{},{}, matrix(uno(), tradeIndex, empty)),
   "purchase_price": forall({},{},{}, matrix(uno(), tradeIndex, empty)),
   "sales_price": forall({},{},{}, matrix(dollar, empty, tradeIndex)),
   "sales": forall({},{},{}, matrix(dollar, empty, duo(compound([Commodity, Year, Region]), uno()))),
   "amount": forall({},{},{}, matrix(uno(), duo(compound([Commodity, Year, Region]), compoundUnit([commodityUnit, uno(), uno()])), empty)),
   "P0": forall({},{},{}, matrix(uno(), duo(compound([Commodity, Year, Region]), uno()), duo(compound([Commodity]), uno()))),
   "P1": forall({},{},{}, matrix(uno(), duo(compound([Commodity, Year, Region]), uno()), duo(compound([Commodity, Year]), uno()))),   
   "P2": forall({},{},{}, matrix(uno(), duo(compound([Year, Commodity]), compoundUnit([uno(), commodityUnit])),
                                        duo(compound([Commodity, Year, Region]), compoundUnit([commodityUnit, uno(), uno()])))),
   "P3": forall({},{},{}, matrix(uno(), duo(compound([Year]), uno()),
                                        duo(compound([Commodity, Year, Region]), compoundUnit([commodityUnit, uno(), uno()])))),
   "join": forall({"a", "b", "u", "v", "w"},{"P", "Q", "R"},{},
  				  function(pair(matrix(unitVar("a"), 
  				  					   duo(entityVar("P"), unitVar("u")),
  				  					   duo(entityVar("Q"), unitVar("v"))),
  				  				matrix(unitVar("b"), 
  				  					   duo(entityVar("Q"), unitVar("v")),
  				  					   duo(entityVar("R"), unitVar("w")))),
				           matrix(multiply(unitVar("a"), unitVar("b")), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("R"), unitVar("w"))))),
	"transpose": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("Q"), reciprocal(unitVar("v"))),
  				  				  duo(entityVar("P"), reciprocal(unitVar("u")))))),
	"total": forall({"a"},{"P", "Q"},{},
  				  function(matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), uno()),
  				  				  duo(entityVar("Q"), uno())),
				           matrix(unitVar("a"), 
  				  				  empty,
  				  				  empty))),
	"sqrt": forall({"a"},{},{},
  				  function(matrix(multiply(unitVar("a"),unitVar("a")), 
  				  				  duo(compound([]), uno()),
  				  				  duo(compound([]), uno())),
				           matrix(unitVar("a"), 
  				  				  duo(compound([]), uno()),
  				  				  duo(compound([]), uno())))),
   "sum": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(pair(matrix(unitVar("a"), 
  				  					   duo(entityVar("P"), unitVar("u")),
  				  					   duo(entityVar("Q"), unitVar("v"))),
  				  				matrix(unitVar("a"), 
  				  					   duo(entityVar("P"), unitVar("u")),
  				  					   duo(entityVar("Q"), unitVar("v")))),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))))),
   "multiply": forall({"a", "b", "u", "v", "w", "z"},{"P", "Q"},{},
				function(pair(matrix(unitVar("a"), 
  				  					 duo(entityVar("P"), unitVar("u")),
  				  					 duo(entityVar("Q"), unitVar("v"))),
  				  			  matrix(unitVar("b"), 
  				  					 duo(entityVar("P"), unitVar("w")),
  				  					 duo(entityVar("Q"), unitVar("z")))),
				         matrix(multiply(unitVar("a"), unitVar("b")), 
  				  				duo(entityVar("P"), multiply(unitVar("u"), unitVar("w"))),
  				  				duo(entityVar("Q"), multiply(unitVar("v"), unitVar("z")))))),
   "negative": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))),
				           matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))))),
   "closure": forall({"u"},{"P"},{},
  				  function(matrix(uno(), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("P"), unitVar("u"))),
				           matrix(uno(), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("P"), unitVar("u"))))),
   "reciprocal": forall({"a", "u", "v"},{"P", "Q"},{},
  				  function(matrix(unitVar("a"), 
  				  				  duo(entityVar("P"), unitVar("u")),
  				  				  duo(entityVar("Q"), unitVar("v"))),
				           matrix(reciprocal(unitVar("a")), 
  				  				  duo(entityVar("P"), reciprocal(unitVar("u"))),
  				  				  duo(entityVar("Q"), reciprocal(unitVar("v")))))));
}

public void show (str exp) {
	try {
		glbcounter = 0;
		glbstack = [];
		parsed = parseImplodePacioli(exp);
		<typ, _> = inferType(parsed, env());
		println("<pprint(parsed)> :: <pprint(unfresh(typ))>");
	} catch err: {
		println(err);
	}

	
}
	
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
	show("lambda x sum(multiply(x,metre),multiply(gram,metre))");
	
	println("\nThe type system derives a most general type."); 
	show("lambda x lambda y sum(multiply(x,y),multiply(gram,metre))");
}
	
public void demo2() {
	
	// General
	show("lambda x join(x,x)");
	show("lambda x sum(sum(x,x),sum(x,x))");
	show("lambda x multiply(sum(x,x),sum(x,x))");
	show("lambda x lambda y join (sum(x,negative(y)),sum(y,negative(x)))");
	
	// Norm
	show("lambda x total multiply (x,x)");
	show("lambda x sqrt total multiply (x,x)");
	
	// Lie algebras
	show("lambda x lambda y sum(join(x,y),negative(join(y,x)))");
	
	// Netting problem
	show("lambda x join(bom,x)");
	show("(lambda bom2 join(bom2,output)) join(conv,join(bom,reciprocal transpose conv))");
	show("(lambda bom2 closure bom2) join(conv,join(bom,reciprocal transpose conv))");
	
	// Salesdata
	show("multiply(sales,reciprocal transpose amount)");
	show("(lambda price multiply(join(price, reciprocal transpose P2),join(price, reciprocal transpose P2))) multiply(sales,reciprocal transpose amount)");
	show("(lambda price join(price, reciprocal transpose P2)) multiply(sales,reciprocal transpose amount)");
}


module lang::pacioli::utils::demos

import IO;

import lang::pacioli::utils::repl;

////////////////////////////////////////////////////////////////////////////////
// Demos

public void demo0() {
	def("f", "lambda (x) x*x");
	compile("f(2)");
}

public void demo1() {
	println("Functions and tuples in Pacioli");
	compile("apply");
	compile("tuple");
	compile("identity");
}

public void demo2() {

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
	
public void demo3() {
	
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
	
}

public void demo4() {
	
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

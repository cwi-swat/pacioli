module Matrix

import List;
import Relation;
import IO;

alias Matrix[&T,&U] = rel[&T row, &U col, real val];

alias Vector[&T] = rel[&T index, real val];

public real innerProduct(Vector[&T] v1, Vector[&T] v2) {
   return (0.0 | it + a * b | <t, a> <- v1, <t, b> <- v2 );
}

public Vector[&T] addVV(Vector[&T] v1, Vector[&T] v2) {
   return { <t1, v> | <t1, v> <- v1, t1 notin domain(v2) } +
          { <t2, v> | <t2, v> <- v2, t2 notin domain(v1) } +
          { <t, x + y> | <t, x> <- v1, <t, y> <- v2, x + y != 0.0 };
}

public Vector[&T] subVV(Vector[&T] v1, Vector[&T] v2) {
   return { <t1, v> | <t1, v> <- v1, t1 notin domain(v2) } +
          { <t2, -v> | <t2, v> <- v2, t2 notin domain(v1) } +
          { <t, x - y> | <t, x> <- v1, <t, y> <- v2, x - y != 0.0 };
}

public Vector[&T] mulVV(Vector[&T] v1, Vector[&T] v2) {
   return { <t, x * y> | <t, x> <- v1, <t, y> <- v2 };
}

public Vector[&T] divVV(Vector[&T] v1, Vector[&T] v2) {
   return { <t1, v / 0.0> | <t1, v> <- v1, t1 notin domain(v2) } +
          { <t2, 0.0> | <t2, _> <- v2, t2 notin domain(v1) } +
          { <t, x / y> | <t, x> <- v1, <t, y> <- v2  };
}

public Matrix[&T, &U] addMM(Matrix[&T,&U] m1, Matrix[&T,&U] m2) {
  return 
     { <x, y, v> | <x, y, v> <- m1, <x, y> notin m2<0,1> } + 
     { <x, y, v> | <x, y, v> <- m2, <x, y> notin m1<0,1> } + 
     { <x, y, v1 + v2> | <x, y, v1> <- m1, <x, y, v2> <- m2, v1 + v2 != 0.0 };  
}

public Matrix[&T, &U] subMM(Matrix[&T,&U] m1, Matrix[&T,&U] m2) {
  return 
     { <x, y, v> | <x, y, v> <- m1, <x, y> notin m2<0,1> } + 
     { <x, y, -v> | <x, y, v> <- m2, <x, y> notin m1<0,1> } + 
     { <x, y, v1 - v2> | <x, y, v1> <- m1, <x, y, v2> <- m2, v1 - v2 != 0.0 };  
}


public Matrix[&T, &U] mulMS(Matrix[&T, &U] m, real r) {
  return { <x, y, v * r> | <x, y, v> <- m  };  
}

public Vector[&T] mulMV(Matrix[&T, &U] m, Vector[&T] v) {
  return { <t, innerProduct(row(t, m), v)> | t <- m<0> }; 
}

public Matrix[&T, &U] divMV(Matrix[&T, &U] m, Vector[&T] v) {
  return { <t, u, y / x> | <t, x> <- v, <t, u, y> <- m } +
         { <t, u, y / 0.0> | <t, u, y> <- m, t notin domain(v) }; 
}


public Vector[&U] row(&T t, Matrix[&T, &U] m) {
  return m[t];
}

public Vector[&T] col(&U u, Matrix[&T, &U] m) {
  return { <t, v> | <t, u, v> <- m };
}

public Matrix[&T,&V] mulMM(Matrix[&T, &U] m1, Matrix[&U, &V] m2) {
  return { <t, v, x> | t <- m1<0>, v <- m2<1>,
     real x := innerProduct(row(t, m1), col(v, m2)),
     x != 0.0
   };
}


public Matrix[&U, &T] transpose(Matrix[&T, &U] m) {
  return m<1,0,2>;  
}

public Matrix[&T, &T] identity(list[&T] r) {
  return identity(r, r);
}

public Matrix[&T, &U] identity(list[&T] r, list[&U] c) {
  return { <r[i], c[j], 1.0> | i <- domain(r), j <- domain(c), i == j };
}

public void display(Vector[&T] v) {
  for (<k, x> <- v) {
     println("<k> <x>");
  }
}

public void display(list[&T] car, Matrix[&T, &T] m) {
  return display(car, car, m);
}

public void display(list[&T] rc, list[&U] cc, Matrix[&T, &U] m) {
  for (x <- rc) {
    s = "";
    for (y <- cc) {
       value p = 0;
       if (<x, y, v> <- m) {
	  p = v;
       }
       s += "<p> ";
    }
    println(s);
  }  
}

/*

These require lib/ujmp-complete-0.2.5.jar which has not been
committed to the stdlib of Rascal (and will not be).

@doc{Closure over a square matrix}
@javaClass{org.rascalmpl.library.Matrix}
public Matrix[&T,&T] java closure(list[&T] carrier, Matrix[&T, &T] m);

@doc{Inverse of a square matrix}
@javaClass{org.rascalmpl.library.Matrix}
public Matrix[&T,&T] java invert(list[&T] carrier, Matrix[&T, &T] m);

*/


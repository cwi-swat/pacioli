module Matrix

import Map;
import Set;
import List;
import Relation;
import IO;

/*******************************************************************************
 Quick hack for units
 *******************************************************************************/

alias Unit = str;

public Unit sum(Unit x, Unit y) {
  if (x == y) {
    return x;
  } else {
    return "(<x>)+(<y>)"; //throw "Cannot add units <x> and <y>. They should be equal.";
  }
}

public Unit product(Unit x, Unit y) {
  if (x == "") {
    return y;
  } else {
    if (y == "") {
      return x;
    } else {
      return "(<x>)·(<y>)";
    }
  }
}
/*******************************************************************************
 A quantity is a numeric amount with a unit field. 
 *******************************************************************************/

data Quantity = quantity(num amount, Unit unit);

public Quantity scale(Quantity q, num c) {
  return quantity(q.amount*c, q.unit);
}

public Quantity product(Quantity q1, Quantity q2) {
  return quantity(q1.amount * q2.amount, product(q1.unit, q2.unit));
}

public Quantity sum(Quantity q1, Quantity q2) {
  return quantity(q1.amount + q2.amount, product(q1.unit, q2.unit));
}

/*******************************************************************************
 Vectors and matrices
 *******************************************************************************/

alias Vec[&T] = map[&T,Quantity];
alias Mat[&X, &Y] = map[tuple[&X, &Y], Quantity];

public Mat[&T, &T] identity(set[&T] r) {
  return (<x,x> : quantity(1,"") | x <- r);
}
 
public Quantity inner(Vec[&T] v1, Vec[&T] v2) {
   return (quantity(0,"") | sum(it, product(v1[a], v2[a])) 
                          | a <- domain(v1) & domain(v2));
}

public Mat[&X, &Y] sum(Mat[&X, &Y] m0, Mat[&X, &Y] m1) {
   return (<r,c> : sum(deref(m0, r, c), deref(m1, r, c)) 
                    | <r, c> <- domain(m0) + domain(m1));
}

public Quantity deref(Mat[&X, &Y] m, &X r , &Y c) {
  return m[<r,c>] ? quantity(0,"");
}

public Mat[&X, &Y] scale(Mat[&X, &Y] m, num a) {
   return (<r,c> : product(quantity(a,""),m[<r, c>]) | <r, c> <- domain(m) );
}

// waarom kan mult niet overloaden met inner?
public Mat[&T, &V] mult(Mat[&T, &U] m1, Mat[&U, &V] m2) {
   return (<r,c> : inner(row(m1,r), col(m2,c)) | r <- domain(m1)<0>,
                                                 c <- domain(m2)<1>);
}

public Vec[&U] multv(Mat[&T, &U] m1, Vec[&U] v) {
   return (r : inner(row(m1,r), v) | r <- domain(m1)<0>);
}


public Mat[&U, &T] transpose(Mat[&T, &U] m) {
   return (<t[1],t[0]> : m[t] | t <- domain(m));
}

public Mat[&T, &T] star(Mat[&T, &T] m) {
   tmp = identity(theProducts);
   acc = tmp;
   for (i <- [0..30]) {
     tmp = mult(m, tmp);
     acc = sum(acc, tmp);
   }
   return acc;
}

public Mat[&T, &T] plus(Mat[&T, &T] m) {
   tmp = m;
   acc = tmp;
   for (i <- [0..30]) {
     tmp = mult(m, tmp);
     acc = sum(acc, tmp);     
   }
   return acc;
}

public set[&T] primaldomain(Mat[&T,&U] m) {
  return domain(m)<0>;  
}

public set[&U] dualdomain(Mat[&T,&U] m) {
  return domain(m)<1>;  
}

public Vec[&T] row(Mat[&T, &U] m, &T r) {
  return (c : m[<r, c>] | <r, c> <- domain(m) );
}

public Vec[&T] col(Mat[&T, &U] m, &T c) {
  return (r : m[<r, c>] | <r, c> <- domain(m) );
}

public void display(Mat[&T, &U] m) {
  for (&T r <- primaldomain(m)) {
    for (&U c <- dualdomain(m)) {
       p = m[<r,c>] ? quantity(0,"");
       x = r; //.name;
       y = c; //.name;
       a = p.amount; // amount(p);
       // Raar dat de volgende test nodig is. Reproduceert niet in de repl
       if (a != 0.0 && a != 0) {
         println("<x>, <y> -\> <p.amount> <p.unit>");
       }
    }
  }  
}

public void displayv(Vec[&T] v) {
  for (&T r <- domain(v)) {
       p = v[r] ? quantity(0,"");
       x = r; //.name;
       a = p.amount; // amount(p);
       // Raar dat de volgende test nodig is. Reproduceert niet in de repl
       if (a != 0.0 && a != 0) {
         println("<x> -\> <p.amount> <p.unit>");
       }
  }  
}


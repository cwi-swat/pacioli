module Closure

import Matrix;

/*******************************************************************************
 Inverse
 
 The closure of a numerical relation R  is determined by calculating the 
 inverse of matrix I-R.
 
 Calculates the inverse of matrix A by solving equation A·X=I. This equation is
 rewritten by eliminating every element from the carrier set until the equation
 I·X=B is arrived at. 
 
 Data type Eqn stores the A and I from the equation. Elimination performs the 
 proper actions on A and I that eventually lead to I and B.
 *******************************************************************************/

data Eqn[&T] = eqn(Mat[&T,&T] left, Mat[&T,&T] right);

public Mat[&T,&T] closure(Mat[&T,&T] m, set[&T] carrier) {
  eq = eqn(sum(identity(carrier), scale(m, -1)),identity(carrier));
  for(p <- carrier) {
    eq = eliminate(p, eq, carrier);
  }
  return eq.right;
} 

public Eqn[&T] eliminate(&T item, Eqn[&T] eq, set[&T] carrier) {
  right = (<r,c> : yo2(eq.left, r, c, item, eq.right) | r <- carrier, c <- carrier);
  left = (<r,c> : yo2(eq.left, r, c, item, eq.left) | r <- carrier, c <- carrier);
  return eqn(left, right);
}

public Quantity yo2(Mat[&T,&T] m, &T r, &T c, &T item, Mat[&T,&T] m2) {
  d = deref(m,item,item).amount;
  if (d == 0) {
    throw("singular");
  } else {
    if (r == item) {
      return scale(deref(m2,r,c), 1/d);
    } else {
      s = deref(m,r,item).amount / d;
      return sum(deref(m2,r,c), scale(deref(m2,item,c),-s)); 
    }
  }
}


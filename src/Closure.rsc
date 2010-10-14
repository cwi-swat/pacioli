module Closure

import Matrix;

public int x = 0;

//rel[int,int] T init R satisfy
//T = T union (T o R) end equations

public Matrix[&T, &U] relToMatrix(rel[&T, &U] r) {
  return r join {1.0};
}

public Matrix[&T, &T] closure(Matrix[&T, &T] m) {
  Matrix[&T, &T] clos = m;
  return solve (clos) {
   clos += mulMM(clos, m);
  }
}
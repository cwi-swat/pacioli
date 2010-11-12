module Pacioli

import Matrix;
import IO;
import List;
import Closure;
import Map;



/*******************************************************************************
 Dictionary
 *******************************************************************************/

data Product = product(str name);

alias Pricing = map[Product,Quantity];

/*******************************************************************************
 Example I
 *******************************************************************************/

public void example1() {
  println("\nOriginal matrix");
  display(bom);  
  println("\nstar with inverse:");
  display(closure(bom, theProducts));
  println("\nand with plus:");    
  display(plus(bom));
} 

public Vec[Product] sp = (
 product("koffie"): quantity(2.25, "euro/kopje"),
 product("appelgebak"): quantity(4.40, "euro/punt")
  
);

public set[Product] theProducts = {
  product("taart"),
  product("appelgebak"),
  product("appels"),
  product("deeg"),
  product("suiker"),
  product("bloem"),
  product("boter"),
  product("eieren"),
  product("rozijnen"),
  product("room"),
  product("koffiebonen"),
  product("koffie")
};

public Mat[Product, Product] bom = (
  <product("taart"), product("appelgebak")> :   quantity(0.125, ""),
  <product("appels"), product("taart")> :       quantity(2.0, ""),
  <product("deeg"), product("taart")> :         quantity(1.0, "kg"),
  <product("suiker"), product("taart")> :       quantity(0.5, "kg"),
  <product("bloem"), product("deeg")> :         quantity(0.33, "kg/kg"),
  <product("boter"), product("deeg")> :         quantity(0.33, "kg/kg"),
  <product("eieren"), product("deeg")> :        quantity(0.33, "kg/kg"),
  <product("koffiebonen"), product("koffie")> : quantity(200, "g/kop"),
  <product("koffie"), product("koffiebonen")> : quantity(0, "g/kop")
);


public Pricing sales = (
 product("koffie"): quantity(2.25, "euro/kopje"),
 product("appelgebak"): quantity(4.40, "euro/punt")
  
);

/*******************************************************************************
 Example II
 *******************************************************************************/

public void example2() {
  println("\nOriginal matrix");
  display(bom2);  
  println("\nstar with inverse:");
  display(closure(bom2, theProducts2));
  println("\nand with plus:");    
  display(plus(bom2));
}

public set[Product] theProducts2 = {
  product("U235"),
  product("U238")
};

public Mat[Product, Product] bom2 = (
  <product("U238"), product("U235")> :   quantity(100, ""),
  <product("U238"), product("U238")> :   quantity(1.01, "")
);

public Vec[Product] ura = (
 product("U235"): quantity(1, "g"),
 product("U238"): quantity(0, "g")
  
);

/*******************************************************************************
 Example III
 *******************************************************************************/

public void example3() {
  println("\nOriginal matrix");
  display(bom3);  
  println("\nstar with inverse:");
  display(closure(bom3, theProducts3));
  println("\nand with plus:");    
  display(plus(bom3));
}

public set[Product] theProducts3 = {
  product("Procurement"),
  product("Production"),
  product("Sales"),
  product("IT"),
  product("HR")
};

public Mat[Product, Product] bom3 = (
  <product("IT"), product("Procurement")> :   quantity(6.0/85.0, ""),
  <product("IT"), product("Production")> :   quantity(60.0/85.0, ""),
  <product("IT"), product("Sales")> :   quantity(8.0/85.0, ""),
  <product("IT"), product("IT")> :   quantity(9.0/85.0, ""),
  <product("IT"), product("HR")> :   quantity(2.0/85.0, ""),
  <product("HR"), product("Procurement")> :   quantity(6.0/69.0, ""),
  <product("HR"), product("Production")> :   quantity(50.0/69.0, ""),
  <product("HR"), product("Sales")> :   quantity(8.0/69.0, ""),
  <product("HR"), product("IT")> :   quantity(3.0/69.0, ""),
  <product("HR"), product("HR")> :   quantity(2.0/69.0, "")
);

public Vec[Product] cost3 = (
 product("Procurement"): quantity(400000.00, "EUR"),
 product("Production"): quantity(3000000.00, "EUR"),
 product("Sales"): quantity(500000, "EUR"),
 product("IT"): quantity(500000, "EUR"),
 product("HR"): quantity(100000, "EUR")
  
);

/*******************************************************************************
 Old stuff
 *******************************************************************************/

/*

public Pricing purchase = (
 product("koffiebonen"): quantity(2.25, "euro/kg"),
 product("appels"): quantity(4.40, "euro/kg"),
 product("deeg"): quantity(2.25, "euro/kg"),
 product("bloem"): quantity(2.25, "euro/kg"),
 product("boter"): quantity(2.25, "euro/kg"),
 product("eieren"): quantity(2.25, "euro/stuk"),
 product("suiker"): quantity(4.40, "euro/kg"),
 product("rozijnen"): quantity(2.25, "euro/kg"),
 product("room"): quantity(4.40, "euro/liter")
);

alias BOM = Matrix[Product,Product];

public BOM bom = {
  <product("taart"),  product("appelgebak"), 0.125>,
  <product("appels"), product("taart"), 2.0>,
  <product("deeg"),   product("taart"), 1.0>,
  <product("suiker"), product("taart"), 0.5>,
  <product("bloem"),  product("deeg"), 0.33>,
  <product("boter"),  product("deeg"), 0.33>,
  <product("eieren"), product("deeg"), 0.33>,
  <product("koffiebonen"), product("koffie"), 0.2>
};



public list[Product] products = [
product("taart"),
product("appelgebak"),
product("appels"),
product("deeg"),
product("suiker"),
product("bloem"),
product("boter"),
product("eieren"),
product("rozijnen"),
product("room"),
product("koffiebonen"),
product("koffie")
];


alias Volume = Vector[Product];

public Volume output = {
 <product("koffie"), 600.0>,
 <product("appelgebak"), 400.0>
}; 

public Volume total = {
<product("taart"), 70.0>,
<product("appelgebak"), 500.0>,
<product("appels"), 1000.9>,
<product("deeg"), 123.3>,
<product("suiker"), 102.3>,
<product("bloem"), 2340.23>,
<product("boter"), 1000.0>,
<product("eieren"), 800.90>,
<product("rozijnen"), 320.30>,
<product("room"), 873.90>,
<product("koffiebonen"), 271.37>,
<product("koffie"), 700.0>
};


// vector of fractions
public Vector[Product] reject = {
<product("taart"), 0.02>,
<product("appelgebak"), 0.01>,
<product("appels"), 0.05>,
<product("deeg"), 0.04>,
<product("suiker"), 0.01>,
<product("bloem"), 0.02>,
<product("boter"), 0.01>,
<product("eieren"), 0.01>,
<product("rozijnen"), 0.001>,
<product("room"), 0.1>,
<product("koffiebonen"), 0.08>,
<product("koffie"), 0.01>
};

public Vector[Product] success = subVV({ <p, 1.0> | p <- products }, reject);


public Volume predictedTotal(list[Product] products, BOM bom, Volume output, Vector[Product] success) {
  return mulMV(closure(products, divMV(bom, success)), divVV(output, success));
} 

public Volume myTotal(BOM bom, Volume output, Vector[Product] success) {
  return mulMV(closure(divMV(bom, success)), divVV(output, success));
} 

public Vector[Product] actualRejectRatio(BOM bom, Volume output, Volume total) {
  return divVV(addVV(output, mulMV(bom, total)), total);
}


public Volume expectedOutput(BOM bom, Volume total, Vector[Product] success) {
  return subVV(mulVV(success, total), mulMV(bom, total));
}
*/
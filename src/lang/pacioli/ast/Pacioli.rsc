module lang::pacioli::ast::Pacioli

data Pacioli = Pacioli(Module mod);

data Module = Module(list[Definition] defs);

data Definition = Definition(str name, Expression exp);

data Expression =  Const(real number);

anno loc Pacioli@location;
anno loc Module@location;
anno loc Definition@location;
anno loc Expression@location;

public str method(str name, list[str] params, str body) {
  return "
public Object <name>() {
<body>
}
";
}


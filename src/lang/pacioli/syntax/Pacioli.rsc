module lang::pacioli::syntax::Pacioli

extend lang::pacioli::syntax::Lexical;
extend lang::pacioli::syntax::KernelPacioli;

start syntax Pacioli = Pacioli: Module mod;

syntax Module = Module: Definition* ;

syntax Definition = Definition: Ident name "=" Expression exp;


Matrix VM - Paul Griffioen 2011

Program ::= Command | Command ';' Program

Command ::= 'skip'
          | 'set' Identifier Identifier
          | 'log' String
          | 'print' Identifier
          | 'abort' String
          | 'load' Identifier String String String String
          | 'conversion' Identifier String String String
          | 'projection' Identifier String String
          | 'unit' Identifier String Unit
          | 'baseunit' Identifier String
          | 'entity' Identifier String
          | 'index' Identifier Identifier String
          |  Unop Identifier Identifier
          |  Binop Identifier Identifier Identifier

Unop ::= 'transpose' | 'negative' | 'reciprocal' | 'closure'

Binop ::= 'sum' | 'multiply' | 'join'


Unit ::= OneUnit
       | OneUnit '*' OneUnit
       | OneUnit '/' OneUnit
       | OneUnit '^' Number

OneUnit ::= Identifier
          | Identifier Identifier
          | Number
          | '(' Unit ')'


Index ::= EntityList '.' UnitList
        | 'empty'

EntityList ::= Identifier | Identifier ',' EntityList

UnitList ::= Unit | Unit ',' UnitList


The matrix type is written as Unit 'x' Index 'per' Index. If matrix A has
type "a x r per c" then matrix entry A_ij has unit a*r_i/c_j.


After 'load id s0 s1 s2 s3' identifier 'id' names a matrix loaded from
source 's0' of type 'unit x rowIndex per columnIndex' with
  unit = parseUnit(s1)
  rowIndex = parseIndex(s2)
  columnIndex = parseIndex(s3)

After 'conversion id s0 s1 s2' identifier 'id' names a conversion matrix 
of type 'unit x rowIndex per columnIndex' with
  unit = 1
  rowIndex = parseIndex(s0 + '.' + s2)
  columnIndex = parseIndex(s0 + '.' + s1)

After 'projection id s0 s1' identifier 'id' names a projection matrix 
of type 'unit x rowIndex per columnIndex' with
  unit = 1
  rowIndex = parseIndex(s0)
  columnIndex = parseIndex(s1)


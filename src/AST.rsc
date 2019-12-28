module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = question(str description, AId id, AType questionType, AExpr expr = empty())
  | block(list[AQuestion] questions)
  | if_then(AExpr condition, AQuestion ifTrue)
  | if_then_else(AExpr condition, AQuestion ifTrue, AQuestion ifFalse)
  ;

data AExpr(loc src = |tmp:///|)
  = empty() // Used to generalize computed and non-computed question to just "question" via setting the default value for expr.
  | ref(AId id)
  | literal(ALiteral l)
  
  | not(AExpr expr)
  
  | mul(AExpr l, AExpr r)
  | div(AExpr l, AExpr r)
  
  | add(AExpr l, AExpr r)
  | sub(AExpr l, AExpr r)
  
  | greater(AExpr l, AExpr r)
  | less(AExpr l, AExpr r)
  | leq(AExpr l, AExpr r)
  | geq(AExpr l, AExpr r)
  
  | eq(AExpr l, AExpr r)
  | neq(AExpr l, AExpr r)
  
  | and(AExpr l, AExpr r)
  
  | or(AExpr l, AExpr r)
  ;

data AId(loc src = |tmp:///|)
  = id(str name)
  ;

data AType(loc src = |tmp:///|)
  = boolean()
  | integer()
  | string()
  ;

data ALiteral
  = string(str s)
  | integer(int i)
  | boolean(bool b)
  ;
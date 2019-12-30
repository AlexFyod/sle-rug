module CST2AST

import Syntax;
import AST;

import IO;

import ParseTree;
import String;
import Boolean;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return form("<f.id>", [cst2ast(question) | question <- f.questions], src=f@\loc); 
}

AQuestion cst2ast(Question q) {
  switch (q) {
    case "question"(label, name, questionType):
      return question("<label>", id("<name>"), cst2ast(questionType), src=q@\loc);
      
    case "computed_question"(label, name, questionType, expr):
      return question("<label>", id("<name>"), cst2ast(questionType), expr = cst2ast(expr), src=q@\loc);
      
    case "block"(Question* questions):
      return block([cst2ast(question) | question <- questions], src=q@\loc);
      
    case "if_then_else"(expr, ifTrue, ifFalse):
      return if_then_else(cst2ast(expr), cst2ast(ifTrue), cst2ast(ifFalse), src=q@\loc);
      
    case "if_then"(expr, ifTrue):
      return if_then(cst2ast(expr), cst2ast(ifTrue), src=q@\loc);
      
    default:
      throw "Unhandled question <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {  
    case "id"(Id x):
      return ref(id("<x>", src=x@\loc), src=x@\loc);
    case "literal"(l):
      return literal(cst2ast(l), src=e@\loc);
    case "parentheses"(x):
      return cst2ast(x);
      
    case "not"(x):
      return not(cst2ast(x), src=e@\loc);
      
    case "mul"(l, r):
      return mul(cst2ast(l), cst2ast(r), src=e@\loc);
    case "div"(l, r):
      return div(cst2ast(l), cst2ast(r), src=e@\loc);
      
    case "add"(l, r):
      return add(cst2ast(l), cst2ast(r), src=e@\loc);
    case "sub"(l, r):
      return sub(cst2ast(l), cst2ast(r), src=e@\loc);
      
    case "greater"(l, r):
      return greater(cst2ast(l), cst2ast(r), src=e@\loc);
    case "less"(l, r):
      return less(cst2ast(l), cst2ast(r), src=e@\loc);
    case "leq"(l, r):
      return leq(cst2ast(l), cst2ast(r), src=e@\loc);
    case "geq"(l, r):
      return geq(cst2ast(l), cst2ast(r), src=e@\loc);
      
    case "eq"(l, r):
      return eq(cst2ast(l), cst2ast(r), src=e@\loc);
    case "neq"(l, r):
      return neq(cst2ast(l), cst2ast(r), src=e@\loc);
      
    case "and"(l, r):
      return and(cst2ast(l), cst2ast(r), src=e@\loc);
    case "or"(l, r):
      return or(cst2ast(l), cst2ast(r), src=e@\loc);
    
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
  switch (t) {
    case (Type)`boolean`:
      return boolean();
    case (Type)`integer`:
      return integer();
    case (Type)`string`:
      return string();
    default:
      throw "Unhandled type: <t>";
  }
}

ALiteral cst2ast(Literal l) {
  switch (l) {
    case (Literal)`<Str s>`:
      return string("<s>");
    case (Literal)`<Int i>`:
      return integer(toInt("<i>"));
    case (Literal)`<Bool b>`:
      return boolean(fromString("<b>"));
    default:
      throw "Unhandled literal: <l>";
  }
}

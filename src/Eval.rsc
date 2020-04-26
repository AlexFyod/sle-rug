module Eval

import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int i)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  return (q.id.name : initialValue(q.questionType) | /AQuestion q := f.questions);
}

Value initialValue(AType t) {
  switch (t) {
    case integer(): return vint(0);
    case boolean(): return vbool(false);
    case string():  return vstr("");
    default:        throw "Unsupported type: <t>";
  }
}

// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
  return ();
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for (/AQuestion q := f.questions) {
    venv += eval(q, inp, venv);
  }
  return venv;
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  switch (q) {
    case question(_, id(name), _, expr = AExpr e):
      if (e == empty()) {
        return venv + (name == inp.question
                       ? (name: inp.\value)
                       : ());
      } else {
        return venv + (name: eval(e, venv));
      }
    case block(questions):
      return evalQuestionList(questions, inp, venv); 
    case if_then(condition, ifTrue):
      return evalIfBlock(condition, ifTrue, inp, venv);
    case if_then_else(condition, ifTrue, ifFalse):
      return evalIfElseBlock(condition, ifTrue, ifFalse, inp, venv);
  }
  return venv; 
}

VEnv evalQuestionList(list[AQuestion] questions, Input inp, VEnv venv) {
  for (AQuestion question <- questions) {
    venv += eval(question, inp, venv);
  }
  return venv;
}

VEnv evalIfBlock(AExpr condition, AQuestion ifTrue, Input inp, VEnv venv) {
  return venv + (eval(condition, venv).b
                ? eval(ifTrue, inp, venv)
                : ());
}

VEnv evalIfElseBlock(AExpr condition, AQuestion ifTrue, AQuestion ifFalse, Input inp, VEnv venv) {
  return venv + (eval(condition, venv).b
                 ? eval(ifTrue, inp, venv)
                 : eval(ifFalse, inp, venv));
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(id(name)):     return venv[name];
    case literal(l):        return eval(l);
    
    case parentheses(expr): return eval(expr, venv);
    
    case not(expr):         return vbool(!(eval(expr, venv).b));
    
    case mul(l, r):         return vint(eval(l, venv).i * eval(r, venv).i);
    case div(l,  r):        return vint(eval(l, venv).i / eval(r, venv).i);
    
    case add(l, r):         return vint(eval(l, venv).i + eval(r, venv).i);
    case sub(l, r):         return vint(eval(l, venv).i - eval(r, venv).i);
    
    case greater(l, r):     return vbool(eval(l, venv).i > eval(r, venv).i);
    case less(l, r):        return vbool(eval(l, venv).i < eval(r, venv).i);
    case leq(l, r):         return vbool(eval(l, venv).i <= eval(r, venv).i);
    case geq(l, r):         return vbool(eval(l, venv).i >= eval(r, venv).i);
    
    // For equality operators, we let Rascal perform type checking.
    case eq(l, r):          return vbool(eval(l, venv)   == eval(r, venv));
    case neq(l, r):         return vbool(eval(l, venv)   != eval(r, venv));
    
    case and(l, r):         return vbool(eval(l, venv).b && eval(r, venv).b);
    case or(l, r):          return vbool(eval(l, venv).b || eval(r, venv).b);
    
    default:                throw "Unsupported expression <e>";
  }
}

Value eval(ALiteral l) {
  switch (l) {
    case integer(int i):  return vint(i);
    case boolean(bool b): return vbool(b);
    case string(str s):   return vstr(s);
    default:              throw "Unsupported literal <l>";
  }
}
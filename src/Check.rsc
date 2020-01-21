module Check

import AST;
import Resolve;
import Message; // see standard library


import IO;
import List;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;
  
str typeName(Type t) {
  switch (t) {
    case tint():  return "integer";
    case tbool(): return "boolean";
    case tstr():  return "string";
    default:      return "unknown";
  }
}
  
Type toType(AType t) {
  switch (t) {
    case integer(): return tint();
    case boolean(): return tbool();
    case string():  return tstr();
    default:        return tunknown();
  }
}

Type toType(ALiteral l) {
  switch (l) {
    case integer(_): return tint();
    case boolean(_): return tbool();
    case string(_):  return tstr();
    default:         return tunknown();
  }
}


// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f)
  = {  <id.src, id.name, description, toType(questionType)>
     | /question(str description, AId id, AType questionType, expr = AExpr e, src = loc def) := f
    }
  ;

set[Message] check(AForm f, TEnv tenv, UseDef useDef)
  = ({} | it + check(question, tenv, useDef) | /AQuestion question := f.questions)
  + ({} | it + check(expr, tenv, useDef)     | /AExpr expr := f)
  ;


// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  switch (q) {
    case question(str label, AId id, AType questionType, expr = AExpr e, src = loc location):
      return
        {  error ("Question <id.name> of type <questionType> is already defined in <env>", location)
         | <env, name, _, questionTypeFromEnv> <- tenv,
           name == id.name,
           location == env,
           toType(questionType) != questionTypeFromEnv
        }
        +
        {  warning("Question with label <label> is already defined in <env>", location)
         | <env, name, labelFromEnv, _> <- tenv,
           location == env,
           id.name != name,
           label == labelFromEnv
        }
        +
        {  error("Declared type of computed question <id.name> does not match the type of expression", location)
         | e != empty(),
           toType(questionType) != typeOf(e, tenv, useDef)        
        };
  }
  
  return {};
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) { 
  switch (e) {
    case ref(AId x):
      return {error("Undeclared question", x.src) | useDef[x.src] == {}};
      
    case not(AExpr expr, src = loc location):
      return checkUnaryBool(e, "!", location, tenv, useDef);
      
    case mul(AExpr l, AExpr r, src = loc location):
      return checkBinaryInt(l, r, "*", location, tenv, useDef);
    case div(AExpr l, AExpr r, src = loc location):
      return checkBinaryInt(l, r, "/", location, tenv, useDef);
      
    case add(AExpr l, AExpr r, src = loc location):
      return checkBinaryInt(l, r, "+", location, tenv, useDef);
    case sub(AExpr l, AExpr r, src = loc location):
      return checkBinaryInt(l, r, "-", location, tenv, useDef);
      
    case greater(AExpr l, AExpr r, src = loc location):
      return checkBinaryInt(l, r, "\>", location, tenv, useDef);
    case less(AExpr l, AExpr r, src = loc location):
      return checkBinaryInt(l, r, "\<", location, tenv, useDef);
    case leq(AExpr l, AExpr r, src = loc location):
      return checkBinaryInt(l, r, "\<=", location, tenv, useDef);
    case geq(AExpr l, AExpr r, src = loc location):
      return checkBinaryInt(l, r, "\>=", location, tenv, useDef);
    
    case eq(AExpr l, AExpr r, src = loc location):  
      return checkEquality(l, r, "==", location, tenv, useDef);
    case neq(AExpr l, AExpr r, src = loc location):
      return checkEquality(l, r, "!=", location, tenv, useDef);
    
    case and(AExpr l, AExpr r, src = loc location):
      return checkBinaryBool(l, r, "&&", location, tenv, useDef);
    case or(AExpr l, AExpr r, src = loc location):
      return checkBinaryBool(l, r, "||", location, tenv, useDef);
      
    default:
      return {};
  }
}

set[Message] checkUnaryBool(AExpr e, str operator, loc location, TEnv tenv, UseDef useDef) {
  Type t = typeOf(e, tenv, useDef);
  return {  error("\"<operator>\" operator must be applied to a boolean expression only. Found: <typeName(t)>", location)
          | t != tbool()
         };
}

set[Message] checkBinaryInt(AExpr l, AExpr r, str operator, loc location, TEnv tenv, UseDef useDef) {
  Type lType = typeOf(l, tenv, useDef);
  Type rType = typeOf(r, tenv, useDef);
  return {  error("\"<operator>\" binary operator must be applied to integers only. Found: <typeName(lType)> and <typeName(rType)>", location)
          | lType != tint() || rType != tint()
         };
}

set[Message] checkEquality(AExpr l, AExpr r, str operator, loc location, TEnv tenv, UseDef useDef) {
  Type lType = typeOf(l, tenv, useDef);
  Type rType = typeOf(r, tenv, useDef);
  return {  error("\"<operator>\" binary operator must be applied to operands of the same type. Found: <typeName(lType)> and <typeName(rType)>", location)
          | lType != rType
         };
}

set[Message] checkBinaryBool(AExpr l, AExpr r, str operator, loc location, TEnv tenv, UseDef useDef) {
  Type lType = typeOf(l, tenv, useDef);
  Type rType = typeOf(r, tenv, useDef);
  return {  error("\"<operator>\" binary operator must be applied to booleans only. Found: <typeName(lType)> and <typeName(rType)>", location)
          | lType != tbool() || rType != tbool()
         };
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    case literal(ALiteral l): return toType(l);
      
    case not(_):              return tbool();
      
    case mul(_, _):           return tint();
    case div(_, _):           return tint();
      
    case add(_, _):           return tint();
    case sub(_, _):           return tint();
      
    case greater(_, _):       return tbool();
    case less(_, _):          return tbool();
    case geq(_, _):           return tbool();
    case leq(_, _):           return tbool();
      
    case eq(_, _):            return tbool();
    case neq(_, _):           return tbool();
    
    case and(_, _):           return tbool();
    case or(_, _):            return tbool();
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 


module Transform

import Syntax;
import Resolve;
import AST;
import Relation;
import ParseTree;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  return f;
}

//AQuestion flatten(question(str label, AId id, AType questionType, AExpr expr)) {
//  return if_then(boolean(true), question(label, id, questionType, expr));
//}

list[AQuestion] flatten(AQuestion q, AExpr globalCondition) {
  switch (q) {
    case question(_, _, _, expr = _):
      return [if_then(globalCondition, q)];
    case block(list[AQuestion] qs):
      return ([] | it + flatten(question, globalCondition) | question <- qs);
    case if_then(AExpr condition, AQuestion ifTrue):
      return flatten(ifTrue, and(condition, globalCondition));
    case if_then_else(AExpr condition, AQuestion ifTrue, AQuestion ifFalse):
      return flatten(ifTrue, and(condition, globalCondition))
           + flatten(ifFalse, and(not(condition), globalCondition));
    default:
      return [];
  }
}



/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
 start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
   UseDef useDefInv = invert(useDef);
   
   set[loc] uses = useDef[useOrDef];
   set[loc] defs = ({} | it + useDefInv[use] | loc use <- uses + {useOrDef});  
   set[loc] locations = {useOrDef} + uses + defs;
   
   Id newId = [Id] newName;
   return visit (f) {
     case "question"(Str label, Id name, Type questionType) =>
       [Question] "<label> <newId> : <questionType>"
         when loc l <- locations,
                  l == name@\loc
     case "computed_question"(Str label, Id name, Type questionType, Expr e) =>
       [Question] "<label> <newId> : <questionType> = <e>"
         when loc l <- locations,
                  l == name@\loc
     case "iden"(id) => 
       [Expr] "<newId>"
         when l <- locations,
              l == id
   };
 } 
 
 
 


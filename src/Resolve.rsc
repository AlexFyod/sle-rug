module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

// Visit all nodes that have ref(AId id), i.e. all AExpr nodes.
Use uses(AForm f)
  = {<source, name> | /ref(id(name), src = loc source) := f}
  ;

// Visit all questions, either computed or non-computed.
// Achieved through generalization of "question" type.
Def defs(AForm f)
  = {<id.name, id.src> | /question(_, AId id, _) := f}
  ;
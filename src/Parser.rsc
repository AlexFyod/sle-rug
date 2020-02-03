module Gen

import ParseTree;
import IO;

import Syntax;
import AST;
import CST2AST;
import Resolve;
import Check;
import Compile;
import Transform;

alias Results = tuple[
  start[Form] pt,
  AForm ast,
  AForm flat,
  RefGraph refs,
  TEnv env,
  set[Message] messages
];

Results parseQL(loc file) {
  cst = parse(#start[Form], file);
  ast = cst2ast(cst);
  flat = flatten(ast);
  res = resolve(ast);
  env = collect(ast);
  messages = check(ast, env, res[2]);
  
  errors = {e | e <- messages, e := error(_, _)};
  warnings = {w | w <- messages, w := warning(_, _)};
  if (errors == {}) {
    if (warnings != {} ) {
      println("Warnings:");
      println(warnings);
    }
    compile(flat);
  } else {
    println("Failed to compile:");
    println(messages);
  }

  return <cst, ast, flat, res, env, messages>;
}
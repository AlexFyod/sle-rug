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

alias CompileResult = tuple[
  start[Form] pt,
  AForm ast,
  AForm flat,
  RefGraph refs,
  TEnv env,
  set[Message] msgs
];

CompileResult initql(loc file) {
  pt = parse(#start[Form], file);

  ast = cst2ast(pt);

  flat = flatten(ast);

  res = resolve(ast);

  env = collect(ast);

  msgs = check(ast, env, res[2]);

  if ({m | m:error(_,_) <- msgs} == {}) {
  	/*
    VEnv venv = initialEnv(ast);

  	Input inp1 = input("sellingPrice", vint(5));
  	Input inp2 = input("privateDebt", vint(2));
  	venv = eval(ast, inp1, venv);
  	venv = eval(ast, inp2, venv);
    */
    compile(flat);
  } else {
    println("Failed to compile, file contains errors.");
    println(msgs);
  }

  return <pt, ast, flat, res, env, msgs>;
}
module Syntax


extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id id "{" Question* questions "}"; 

syntax Question
  = question:			Str Id ":" Type
  | computed_question:	Str Id ":" Type "=" Expr
  | block:				"{" Question* "}"
  | if_then:			"if" "(" Expr ")" Question
  | if_then_else:		"if" "(" Expr ")" Question "else" Question 
  ; 

syntax Expr 
  = id: Id \ "true" \ "false" // true/false are reserved keywords.
  | literal: Literal
  | bracket parentheses:   "(" Expr ")"
  > right not:             "!" Expr
  > left (
           mul:     Expr l "*" Expr r |
           div:     Expr l "/" Expr r
         )
  > left (
           add:     Expr l "+" Expr r |
           sub:     Expr l "-" Expr r
         )
  > left (
           greater: Expr l "\>" Expr r |
           less:    Expr l "\<" Expr r |
           leq:     Expr l "\<=" Expr r |
           geq:     Expr l "\>=" Expr r
         )
  > left (
           eq:      Expr l "==" Expr r | 
           neq:     Expr l "!=" Expr r
         )
  > left (
           and:     Expr l "&&" Expr r
         )
  > left (
           or:      Expr l "||" Expr r
         )
  ;
  
syntax Type
  = "boolean"
  | "integer"
  | "string"
  ;  
  
lexical Str = [\"] ![\"]* [\"];

lexical Int = [0-9]+;

lexical Bool
  = "true"
  | "false"
  ;

lexical Literal
  = Str
  | Int
  | Bool
  ;

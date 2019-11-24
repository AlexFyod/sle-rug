module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

syntax Question
  = question:			Str Id ":" Type
  | computed_question:	Str Id ":" Type "=" Expr
  | block:				"{" Question* "}"
  | if_then_else:		"if" "(" Expr ")" Question "else" Question 
  | if_then:			"if" "(" Expr ")" Question
  ; 

syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | literal: Bool | Int | String
  | parentheses: "(" Expr ")"
  > right not:             "!" Expr e
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
           equal:   Expr l "==" Expr r | 
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



// http://tutor.rascal-mpl.org/Rascal/Declarations/SyntaxDefinition/Disambiguation/Priority/Priority.html
// http://tutor.rascal-mpl.org/Rascal/Rascal.html#/Rascal/Declarations/SyntaxDefinition/Disambiguation/Associativity/Associativity.html
// https://overiq.com/c-programming-101/operator-precedence-and-associativity-in-c/
module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) {
  return html(
           head(
             title(f.name),
             meta(charset("utf-8")),
             meta(name("viewport"), content("width=device-width, initial-scale=1, shrink-to-fit=no")),
         
             link(\rel("stylesheet"), href("https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css")),
             
             
             script(src("https://code.jquery.com/jquery-3.3.1.slim.min.js")),
             script(src("https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js")),
             script(src("https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js")),
             script(src(f.src[extension="js"].file))
           ),
           body(
             div(class("list-group w-25 mw-100 p-3"),
               div(
                 [AQuestion2html(q) | q <- f.questions]
               )
             )
           )
         );
}

HTML5Node AQuestion2html(AQuestion q) {
  switch (q) {
    case question(label, id, questionType, expr = AExpr e):
      return question2html(q);
    case block(questions):
      return div(
               [AQuestion2html(question) | question <- questions]
             );
    case if_then(condition, ifTrue):
      return div(id("<condition.id.name>"), class("d-none"),
               AQuestion2html(ifTrue)          
             );
    case if_then_else(condition, ifTrue, ifFalse):
      return div(id("<condition.id.name>"), class("d-none"),
               AQuestion2html(ifTrue),
               AQuestion2html(ifFalse)
             );
    default: return div();
  }
}

HTML5Node question2html(AQuestion q) {
  HTML5Node inputField = input(class("form-control"),
                               inputType(q.questionType),
                               name("<q.id.name>-input")
                             );
  return div(class("list-group-item"),
              form(id("<q.id.name>"),
                div(class("form-group"),
                  label(\for("<q.id.name>-input"), q.label),
                  inputField,
                  br()
                )
              )
         );
}

HTML5Attr inputType(AType questionType) {
	switch(questionType) {
	    case integer(): return \type("number");
        case boolean(): return \type("checkbox");
        case string():  return \type("text");
        default:        throw "Unsupported type <questionType>";
	}
}

str form2js(AForm f) {
  return "";
}

str expr2js(ALiteral l) {
  switch (l) {
    case integer(int i):  return "<i>";
    case boolean(bool b): return "<b>";
    case string(str s):   return "<s>";
    default:              throw "Unsupported literal <l>";
  }
}

str expr2js(AExpr e) {
  switch (e) {
    case ref(id(name)):         return name;
    case literal(l):            return expr2js(l);
    
    case parentheses(expr):     return "(<expr2js(expr)>)";
    
    case not(expr):             return "!<expr2js(expr)>";
    
    case mul(l, r):             return "<expr2js(l)> * <expr2js(r)>";
    case div(l, r):             return "<expr2js(l)> / <expr2js(r)>";
    
    case add(l, r):             return "<expr2js(l)> + <expr2js(r)>";
    case sub(l, r):             return "<expr2js(l)> - <expr2js(r)>";
    
    case greater(l, r):         return "<expr2js(l)> \> <expr2js(r)>";
    case less(l, r):            return "<expr2js(l)> \< <expr2js(r)>";
    case leq(l, r):             return "<expr2js(l)> \<= <expr2js(r)>";
    case geq(l, r):             return "<expr2js(l)> \>= <expr2js(r)>";
    
    case and(l, r):             return "<expr2js(l)> && <expr2js(r)>";
    case or(l, r):              return "<expr2js(l)> || <expr2js(r)>";
    
    default:                    throw "Unsupported expression <e>";
  }
}
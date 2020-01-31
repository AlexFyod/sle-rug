module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
import List;

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
             script(src("https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js"))
           ),
           body(
             div(class("list-group w-25 mw-100 p-3"),
               div(
                 [AQuestion2html(q) | q <- f.questions]
               )
             )
           ),
          footer(
            script(src(f.src[extension="js"].file))  
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
      return div(id("<condition.id.name>"),
               AQuestion2html(ifTrue)          
             );
    case if_then_else(condition, ifTrue, ifFalse):
      return div(id("<condition.id.name>"),
               AQuestion2html(ifTrue),
               AQuestion2html(ifFalse)
             );
    default: return div();
  }
}

HTML5Node question2html(AQuestion q) {
  HTML5Node inputField = input(class("form-control"),
                               id("<q.id.name>-input"),
                               inputType(q.questionType)
                             );
  return div(class("list-group-item"), id("<q.id.name>-form"),
              form(
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


// JavaScript

str form2js(AForm f) {
  return
"document.addEventListener(\'input\', function () {
'	refresh();
});
refresh();


function refresh() {
'	<getVariables(f)>

'	<intercalate("\n", [question2js(q, true) | q <- f.questions])>
}";
}


str getVariables(AForm f) {
  list[str] variables = [
"let <id.name>Form = document.getElementById(\'<id.name>-form\');
let <id.name> = document.getElementById(\'<id.name>-input\').<getValue(t)>;\n"
      | /question(_, id, t, expr = empty()) := f
  ];
  variables += [""];
  
  variables += [
"let <id.name>Form = document.getElementById(\'<id.name>-form\');
let <id.name> = document.getElementById(\'<id.name>-input\').<getValue(t)> = <expr2js(e)>;
<id.name>.disabled = true;
<id.name>.readOnly = true;"
      | /question(_, id, t, expr = e) := f, e != empty()
  ];
  return intercalate("\n", variables);
}

str getValue(AType t) {
  switch (t) {
    case integer():
      return "value";
    case boolean():
      return "checked";
    case string():
      return "value";
    default:
      throw "Unknown type <t>";
  }
}


str question2js(AQuestion q, bool visible) {
  switch (q) {
  
    case question(_, id, _, expr = e):
      return "<id.name>Form.classList." + (visible ? "remove(\'d-none\')" : "add(\'d-none\');");
      
    case block(questions):
      return "<intercalate("\n", [question2js(question, visible) | question <- questions])>";
  
  
    case if_then(condition, ifTrue):
      return
"if (<expr2js(condition)>) {
'	<question2js(ifTrue, true)>
} else {
'	<question2js(ifTrue, false)>
}
";


    case if_then_else(condition, ifTrue, ifFalse):
      return
"if (<expr2js(condition)>) {
'	<question2js(ifTrue, true)>
'	<question2js(ifFalse, false)>
} else {
'	<question2js(ifTrue, false)>
'	<question2js(ifFalse, true)>
}
";


    default:
      return "";
  }
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
%token <float> FLOAT
%token <string> ID
%token PLUS MINUS TIMES DIV
%token DEF
%token SEMICOLON
%token COMMA
%token LPAREN RPAREN
%token EXTERN
%token EOF

%left PLUS MINUS
%left TIMES DIV 

%start <Astree.expr list> main
%%
main:
| stmt = statement EOF { [stmt] }
| stmt = statement m = main { stmt :: m}

statement:
| e = expr SEMICOLON { e }
| EXTERN s = signature SEMICOLON { s }
| DEF s = signature e = expr SEMICOLON { Astree.Function (s, e) }

expr:
| i = ID { Astree.Variable i }
| x = FLOAT { Astree.Number x }
| e1 = expr PLUS e2 = expr { Astree.Binary ('+', e1, e2) }
| e1 = expr MINUS e2 = expr { Astree.Binary ('-', e1, e2) }
| e1 = expr TIMES e2 = expr { Astree.Binary ('*', e1, e2) }
| e1 = expr DIV e2 = expr { Astree.Binary ('/', e1, e2) }
| name = ID LPAREN args = call_arguments RPAREN { Astree.Call (name, args) }

signature:
| symbol_name = ID LPAREN args = arguments RPAREN { Astree.Prototype (symbol_name, args) }

arguments:
| arg = ID { [arg] }
| arg = ID rest = arguments { arg :: rest}

call_arguments:
| arg = expr { [arg] }
| arg = expr COMMA rest = call_arguments { arg :: rest}

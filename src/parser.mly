%token <float> FLOAT
%token <string> ID
%token PLUS MINUS TIMES DIV
%token DEF
%token SEMICOLON
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
| EXTERN p = prototype SEMICOLON { p }
| DEF name = ID LPAREN arg = ID RPAREN e = expr SEMICOLON { Astree.Function (name, arg, e) } 

expr:
| i = ID { Astree.Variable i }
| x = FLOAT { Astree.Number x }
| e1 = expr PLUS e2 = expr { Astree.Binary ('+', e1, e2) }
| e1 = expr MINUS e2 = expr { Astree.Binary ('-', e1, e2) }
| e1 = expr TIMES e2 = expr { Astree.Binary ('*', e1, e2) }
| e1 = expr DIV e2 = expr { Astree.Binary ('/', e1, e2) }
| name = ID LPAREN e = expr RPAREN { Astree.Call (name, e) }

prototype:
| x = ID LPAREN a1 = ID RPAREN { Astree.Prototype (x, a1) }

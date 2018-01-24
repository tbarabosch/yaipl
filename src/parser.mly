%token <float> FLOAT
%token <string> ID
%token PLUS MINUS TIMES DIV
%token LT GT
%token LOR LAND
%token DEF
%token SEMICOLON
%token COMMA
%token LPAREN RPAREN
%token EXTERN
%token EOF
%token BEGIN END
%token IF THEN ELSE
%token FOR IN
%token ASSIGNMENT

%left LOR LAND
%left LT GT
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
| DEF s = signature BEGIN b = body END { Astree.Function (s, b) }

signature:
| symbol_name = ID LPAREN args = arguments RPAREN { Astree.Prototype (symbol_name, args) }

arguments:
| arg = ID { [arg] }
| arg = ID rest = arguments { arg :: rest}
		
expr:
| LPAREN e = expr RPAREN { e }
| i = ID { Astree.Variable i }
| x = FLOAT { Astree.Number x }
| e1 = expr PLUS e2 = expr { Astree.Binary ('+', e1, e2) }
| e1 = expr MINUS e2 = expr { Astree.Binary ('-', e1, e2) }
| e1 = expr TIMES e2 = expr { Astree.Binary ('*', e1, e2) }
| e1 = expr DIV e2 = expr { Astree.Binary ('/', e1, e2) }
| e1 = expr LT e2 = expr { Astree.Binary ('<', e1, e2) }
| e1 = expr GT e2 = expr { Astree.Binary ('>', e1, e2) }
| e1 = expr LOR e2 = expr { Astree.Binary ('|', e1, e2) }
| e1 = expr LAND e2 = expr { Astree.Binary ('&', e1, e2) }
| name = ID LPAREN args = call_arguments RPAREN { Astree.Call (name, args) }		
| IF condition = expr THEN then_expr = expr ELSE else_expr = expr { Astree.If (condition, then_expr, else_expr) }
| FOR loop_counter = ID ASSIGNMENT loop_start = expr COMMA loop_condition = expr COMMA
  loop_step = expr IN BEGIN b = body END
  { Astree.For (loop_counter, loop_start, loop_condition, loop_step, b)}
		
call_arguments:
| arg = expr { [arg] }
| arg = expr COMMA rest = call_arguments { arg :: rest}

body:
| e = expr { [e] }
| e = expr SEMICOLON b = body { e :: b }

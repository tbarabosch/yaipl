{
open Parser
let get = Lexing.lexeme
}

let digit = ['0'-'9']
let frac = '.' digit*
let exp = ['e' 'E'] ['-' '+']? digit+
let float = digit* frac? exp?

let white = [' ' '\t']+
let newline = '\r' | '\n'
let id = ['a'-'z' 'A'-'Z' '_']['a'-'z' 'A'-'Z' '0'-'9' '_']*

rule read = parse
| white { read lexbuf }
| "#" { comment lexbuf }
| newline { read lexbuf }
| float { FLOAT (float_of_string (get lexbuf))}
| ';' { SEMICOLON }
| ',' { COMMA }
| '+' { PLUS }
| '-' { MINUS }
| '*' { TIMES }
| '/' { DIV }
| '(' { LPAREN }
| ')' { RPAREN }
| "def" { DEF }
| "extern" { EXTERN }
| id {ID (get lexbuf)}
| _ { raise (Error)}
| eof { EOF }
and comment = parse
 '\n' { read lexbuf }
 | _ { comment lexbuf }
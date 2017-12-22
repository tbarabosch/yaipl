open Core.Std

let rec pprint_expr e = match e with 
   | Astree.Number v -> print_string (string_of_float v)
   | Astree.Variable v -> print_string v
   | Astree.Binary (op,oper1,oper2) -> print_char op; pprint_expr oper1; pprint_expr oper2;
   | Astree.Call (n, _) -> print_string n;
   | Astree.Prototype (name,arg) -> Printf.printf "%s(%s)" name arg
   | Astree.Function (name, arg ,e) -> Printf.printf "%s(%s)" name arg; pprint_expr e
  
let rec pprint_list ast_list = match ast_list with
  | hd :: tl -> pprint_expr hd; pprint_list tl
  | _ -> () 

let parse lexbuf =
    let ast = Parser.main Lexer.read lexbuf in
    print_char '\n';
    pprint_list(ast);
    print_char '\n'
                               
let () =
  print_string "ready> "; flush stdout;
  let lexbuf = Lexing.from_channel stdin in
  try
    parse lexbuf
  with
    Parser.Error -> Printf.printf "Parsing error.\n";
                    
()

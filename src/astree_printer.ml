open Core_kernel

let arguments_to_string args = 
  String.concat args ~sep:" "
   
let rec pprint_stmt e = match e with 
   | Astree.Number v -> print_string (string_of_float v)
   | Astree.Variable v -> print_string v
   | Astree.Binary (op,oper1,oper2) -> Out_channel.printf "%c" op; pprint_stmt oper1; pprint_stmt oper2;
   | Astree.Call (n, _) -> print_string n
   | Astree.Prototype (name, arg) -> Printf.printf "%s(%s)" name (arguments_to_string arg)
   | Astree.Function (signature, e) -> pprint_stmt signature; pprint_stmt e 
  
let rec pprint_list ast_list = match ast_list with
  | hd :: tl -> pprint_stmt hd; Printf.printf "\n"; pprint_list tl
  | _ -> () 

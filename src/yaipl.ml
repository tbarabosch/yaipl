open Core_kernel
open Llvm

let rec codegen_list ast_list = match ast_list with
  | hd :: tl -> dump_value (Codegen.codegen_stmt hd); Format.printf "\n"; codegen_list tl
  | [] -> ()
   
let parse lexbuf =
  let ast = Parser.main Lexer.read lexbuf in
  codegen_list ast
                               
let () =
  print_string "ready> "; Out_channel.flush stdout;
  let lexbuf = Lexing.from_channel In_channel.stdin in
  try
    parse lexbuf;
    (* dump_module Codegen.the_module *)
  with
    Parser.Error -> Printf.printf "Parsing error.\n"

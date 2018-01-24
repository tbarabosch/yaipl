open Core_kernel
open Llvm

let rec codegen_list ast_list pass_manager = match ast_list with
  | hd :: tl ->
     begin
       dump_value (Codegen.codegen_stmt hd pass_manager);
       Format.printf "\n";
       codegen_list tl pass_manager;
     end
  | [] -> ()
   
let parse lexbuf pass_manager =
  let ast = Parser.main Lexer.read lexbuf in
  codegen_list ast pass_manager
  
let rec repl pass_manager = 
    print_string "ready> "; Out_channel.flush stdout;

    let lexbuf = Lexing.from_channel In_channel.stdin in
    try
      parse lexbuf pass_manager;
      (* dump_module Codegen.the_module *)
      Out_channel.newline stdout;
      repl pass_manager
    with
      Parser.Error ->
       begin
         Printf.printf "Parsing error.\n";
         repl pass_manager
       end
                      
let () =
  let pass_manager = Optimization.setup_optimization () in
  repl pass_manager

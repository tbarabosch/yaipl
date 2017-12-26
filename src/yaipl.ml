open Core_kernel
open Llvm
open Llvm_executionengine
open Llvm_target
open Llvm_scalar_opts

let setup_optimization () =
  let the_fpm = PassManager.create_function Codegen.the_module in
    add_instruction_combination the_fpm;
    add_reassociation the_fpm;
    add_gvn the_fpm;
    add_cfg_simplification the_fpm;
    ignore (PassManager.initialize the_fpm);
    the_fpm

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
  let pass_manager = setup_optimization () in
  repl pass_manager

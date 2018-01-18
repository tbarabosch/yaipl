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

let compile src pass_manager =
  let lexbuf = Lexing.from_channel src in
    try
      parse lexbuf pass_manager;
      (* dump_module Codegen.the_module *)
      Out_channel.newline stdout;
    with
      Parser.Error -> Printf.printf "Parsing error.\n"
      
let () =
  if Array.length Sys.argv != 2 then
    begin
      Format.printf "Usage: yaiplc SOURCE_FILE\n"
    end
  else
    begin
      let pass_manager = setup_optimization () in
      let src_filename = Sys.argv.(1) in
      let src = In_channel.create src_filename in
      compile src pass_manager
    end

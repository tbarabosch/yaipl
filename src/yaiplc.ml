open Core_kernel
open Llvm

let rec codegen_list ast_list pass_manager = match ast_list with
  | hd :: tl ->
     begin
       ignore (Codegen.codegen_stmt hd pass_manager);
       codegen_list tl pass_manager
     end                                           
  | [] -> ()
   
let parse lexbuf pass_manager =
  let ast = Parser.main Lexer.read lexbuf in
  codegen_list ast pass_manager

let compile src pass_manager =
  let lexbuf = Lexing.from_channel src in
    try
      parse lexbuf pass_manager
    with
      Parser.Error -> Format.printf "Parsing error\n"
  
let () =
  if Array.length Sys.argv != 3 then
    begin
      Format.printf "Usage: yaiplc SOURCE_FILE OUT_FILE\n"
    end
  else
    begin
      let pass_manager = Optimization.setup_optimization () in
      let src_filename = Sys.argv.(1) in
      let src = In_channel.create src_filename in
      compile src pass_manager;
      Emit.write_llcode_to_file Codegen.the_module Sys.argv.(2);
      Emit.write_object_file Codegen.the_module Sys.argv.(2)
    end

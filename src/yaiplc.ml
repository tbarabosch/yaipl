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
       string_of_llvalue (Codegen.codegen_stmt hd pass_manager) :: codegen_list tl pass_manager
  | [] -> []
   
let parse lexbuf pass_manager =
  let ast = Parser.main Lexer.read lexbuf in
  codegen_list ast pass_manager

let compile src pass_manager =
  let lexbuf = Lexing.from_channel src in
    try
      Ok (parse lexbuf pass_manager)
    with
      Parser.Error -> Error "Parsing error"

let write_llcode_to_file llcode out_file =
  let out_handle = Out_channel.create out_file in
  List.iter llcode ~f:(fun s -> Printf.fprintf out_handle "%s" s);
  Out_channel.close out_handle
      
let () =
  if Array.length Sys.argv != 3 then
    begin
      Format.printf "Usage: yaiplc SOURCE_FILE OUT_FILE\n"
    end
  else
    begin
      let pass_manager = setup_optimization () in
      let src_filename = Sys.argv.(1) in
      let src = In_channel.create src_filename in
      match compile src pass_manager with
      | Ok llcode -> write_llcode_to_file llcode Sys.argv.(2)
      | Error e -> Format.printf "%s\n" e
    end

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

let write_llcode_to_file llmodule out_file =
  let out_handle = Out_channel.create (out_file ^ ".ll") in
  Printf.fprintf out_handle "%s" @@ string_of_llmodule llmodule;
  Out_channel.close out_handle

let get_target_machine triple =
  let lltarget  = Llvm_target.Target.by_triple triple in
  Llvm_target.TargetMachine.create ~triple:triple lltarget
  
let prepare_module_for_compilation llm triple =
  Llvm_all_backends.initialize ();
  let llmachine = get_target_machine triple in
  let lldly     = Llvm_target.TargetMachine.data_layout llmachine in
  set_target_triple (Llvm_target.TargetMachine.triple llmachine) llm ;
  set_data_layout (Llvm_target.DataLayout.as_string lldly) llm 
  
let write_object_file llmodule out_file =
  let default_triple = Llvm_target.Target.default_triple () in
  prepare_module_for_compilation llmodule default_triple;
  Llvm_analysis.assert_valid_module llmodule;
  Llvm_target.TargetMachine.emit_to_file
    llmodule
    Llvm_target.CodeGenFileType.ObjectFile
    (out_file ^ ".o")
    (get_target_machine default_triple)
  
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
      compile src pass_manager;
      write_llcode_to_file Codegen.the_module Sys.argv.(2);
      write_object_file Codegen.the_module Sys.argv.(2)
    end

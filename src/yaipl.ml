open Core_kernel
open Llvm
open Llvm_executionengine
open Llvm_target
open Llvm_scalar_opts

type jit_ctxt =
  {
    execution_engine: Llvm_executionengine.llexecutionengine;
    pass_manager: [ `Function ] PassManager.t;
  }
   
let setup_optimization () =
  let the_execution_engine = Llvm_executionengine.create Codegen.the_module in
  let the_fpm = PassManager.create_function Codegen.the_module in
    add_instruction_combination the_fpm;
    add_reassociation the_fpm;
    add_gvn the_fpm;
    add_cfg_simplification the_fpm;
    ignore (PassManager.initialize the_fpm);
    {execution_engine = the_execution_engine; pass_manager = the_fpm;}

let rec codegen_list ast_list jit_context = match ast_list with
  | hd :: tl ->
     begin
       dump_value (Codegen.codegen_stmt hd jit_context);
       Format.printf "\n";
       codegen_list tl jit_context;
     end
  | [] -> ()
   
let parse lexbuf jit_context =
  let ast = Parser.main Lexer.read lexbuf in
  codegen_list ast jit_context

let rec repl jit_context = 
    print_string "ready> "; Out_channel.flush stdout;

    let lexbuf = Lexing.from_channel In_channel.stdin in
    try
      parse lexbuf jit_context;
      (* dump_module Codegen.the_module *)
      Out_channel.newline stdout;
      repl jit_context
    with
      Parser.Error ->
       begin
         Printf.printf "Parsing error.\n";
         repl jit_context
       end
                      
let () =
  let jit_context = setup_optimization in
  repl jit_context

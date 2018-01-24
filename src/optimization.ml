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

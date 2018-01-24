open Core_kernel
open Llvm   

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

val write_llcode_to_file : Llvm.llmodule -> string -> unit
val get_target_machine : string -> Llvm_target.TargetMachine.t
val prepare_module_for_compilation : Llvm.llmodule -> string -> unit
val write_object_file : Llvm.llmodule -> string -> unit

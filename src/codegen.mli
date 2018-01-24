exception Error of string
val context : Llvm.llcontext
val the_module : Llvm.llmodule
val builder : Llvm.llbuilder
val named_values : (string, Llvm.llvalue) Hashtbl.t
val double_type : Llvm.lltype
val codegen_stmt :
  Astree.expr -> [ `Function ] Llvm.PassManager.t -> Llvm.llvalue

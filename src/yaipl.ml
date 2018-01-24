open Core_kernel
open Llvm
open Ctypes
open Foreign

let pass_manager = Optimization.setup_optimization ()

(* taken from https://gist.github.com/hackwaly/ac785114a7d88ba03fef1084ae1c5454 *)
let evaluate_jit stmt =
  let ctx = Codegen.context in
  let m_main = Codegen.the_module in
  let builder = Codegen.builder in
  let float_type = Llvm.float_type ctx in
  let ft_main = Llvm.function_type float_type [||] in
  let f_main = Llvm.declare_function "main" ft_main m_main in
  let bb = Llvm.append_block ctx "entry" f_main in
  Llvm.position_at_end bb builder;
  
  ignore (Llvm.build_ret (Llvm.const_float float_type 42.0) builder);
  Llvm_analysis.assert_valid_function f_main;
  
  let ee = Llvm_executionengine.create m_main in
  let ct = funptr ( void @-> returning float ) in
  (* FIXME segfaults when looking for function! *) 
  let f = Llvm_executionengine.get_function_address "main" ct ee in
  let res = f () in

  print_string "Evaluated to ";
  Out_channel.output_string stdout (Float.to_string res);
  Out_channel.newline stdout;
  
  Llvm_executionengine.dispose ee
         
let rec codegen_list ast_list = match ast_list with
  | hd :: tl ->
     begin
       match hd with
       | Astree.Call _ | Astree.Binary _ ->
          begin
           Out_channel.output_string stdout "JIT\n";
           let stmt = Codegen.codegen_stmt hd pass_manager in
           evaluate_jit stmt; 
           codegen_list tl;
          end
       | _ ->
          begin
           let stmt = Codegen.codegen_stmt hd pass_manager in
           dump_value stmt;
           codegen_list tl;
          end
     end
  | [] -> ()
   
let parse lexbuf =
  let ast = Parser.main Lexer.read lexbuf in
  codegen_list ast
  
let rec repl () =
    print_string "ready> "; Out_channel.flush stdout;

    let lexbuf = Lexing.from_channel In_channel.stdin in
    try
      parse lexbuf;
      Out_channel.newline stdout;
      repl ()
    with
      Parser.Error ->
       begin
         Printf.printf "Parsing error.\n";
         repl ()
       end
                      
let () =
  ignore (Llvm_executionengine.initialize ());
  repl ()

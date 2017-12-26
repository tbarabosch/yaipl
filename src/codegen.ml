open Llvm

exception Error of string

let context = global_context ()
let the_module = create_module context "my cool jit"
let builder = builder context
let named_values:(string, llvalue) Hashtbl.t = Hashtbl.create 10
let double_type = double_type context

let rec codegen_stmt = function
  | Astree.Number n -> const_float double_type n
  | Astree.Variable name ->
     begin
       try
         Hashtbl.find named_values name with
       | Not_found -> raise (Error "unknown variable name")
     end
  | Astree.Binary (op, lhs, rhs) ->
     begin
       let lhs_val = codegen_stmt lhs in
       let rhs_val = codegen_stmt rhs in
       begin
         match op with
         | '+' -> build_fadd lhs_val rhs_val "addtmp" builder
         | '-' -> build_fsub lhs_val rhs_val "subtmp" builder
         | '*' -> build_fmul lhs_val rhs_val "multmp" builder
         | '<' ->
            begin
              let i = build_fcmp Fcmp.Ult lhs_val rhs_val "cmptmp" builder in
              build_uitofp i double_type "booltmp" builder
            end
         | _ -> raise (Error "invalid binary operator")
       end
     end
  | Astree.Call (callee, args) ->
     begin
       let callee =
        match lookup_function callee the_module with
        | Some callee -> callee
        | None -> raise (Error "unknown function referenced")
      in
      let params = params callee in
       
       if Array.length params == List.length args then
         ()
       else
         raise (Error "incorrect # arguments passed");

       let args = List.map codegen_stmt args in
       build_call callee (Array.of_list args) "calltmp" builder
     end
  | Astree.Prototype (name, args) ->
     begin
       let args = Array.of_list args in 
       let doubles = Array.make (Array.length args) double_type in
       let ft = function_type double_type doubles in
       let f = match lookup_function name the_module with
         | None -> declare_function name ft the_module
         | Some f ->
            begin
              if Array.length (basic_blocks f) == 0 then () else
                raise (Error "redefinition of function");

              if Array.length (params f) == Array.length args then () else
                raise (Error "redefinition of function with different # args");
              f
            end
       in
       
       (* ToDo: check for conflicting arguments, e.g. foo(a b a) *)
       Array.iteri (fun i a ->
        let n = args.(i) in
        set_value_name n a;
        Hashtbl.add named_values n a;
      ) (params f);
      f
     end
  | Astree.Function (proto, body) ->
     begin
       Hashtbl.clear named_values;
       let the_function = codegen_stmt proto in
       let bb = append_block context  "entry" the_function in
       position_at_end bb builder;
       try
         let body_stmts = (List.map (fun x -> codegen_stmt x) body) in
           begin
              let _ = build_ret (List.hd (List.rev body_stmts)) builder in
              (* FIXME: Llvm_analysis module unknown *)
              (* Llvm_analysis.assert_valid_function the_function; *)
              the_function
            end
       with e -> delete_function the_function; raise e
     end

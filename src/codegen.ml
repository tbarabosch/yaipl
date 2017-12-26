open Llvm

exception Error of string

let context = global_context ()
let the_module = create_module context "my cool jit"
let builder = builder context
let named_values:(string, llvalue) Hashtbl.t = Hashtbl.create 10
let double_type = double_type context

let rec codegen_stmt ast pass_manager = match ast with
  | Astree.Number n -> const_float double_type n
  | Astree.Variable name ->
     begin
       try
         Hashtbl.find named_values name with
       | Not_found -> raise (Error "unknown variable name")
     end
  | Astree.Binary (op, lhs, rhs) ->
     begin
       let lhs_val = codegen_stmt lhs pass_manager  in
       let rhs_val = codegen_stmt rhs pass_manager in
       begin
         match op with
         | '+' -> build_fadd lhs_val rhs_val "addtmp" builder
         | '-' -> build_fsub lhs_val rhs_val "subtmp" builder
         | '*' -> build_fmul lhs_val rhs_val "multmp" builder
         | '/' -> build_fdiv lhs_val rhs_val "divtmp" builder
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

       let args = List.map (fun arg -> codegen_stmt arg pass_manager) args in
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
       let the_function = codegen_stmt proto pass_manager in
       let bb = append_block context  "entry" the_function in
       position_at_end bb builder;
       try
         let body_stmts = (List.map (fun stmt -> codegen_stmt stmt pass_manager) body) in
           begin
              let _ = build_ret (List.hd (List.rev body_stmts)) builder in
              Llvm_analysis.assert_valid_function the_function;
              let _ = PassManager.run_function the_function pass_manager in
              the_function
            end
       with e -> delete_function the_function; raise e
     end
  | Astree.If (condition, then_expr, else_expr) ->
     begin
       (* resolve condition and compare it to zero *)
       let cond = codegen_stmt condition pass_manager in
       let zero = const_float double_type 0.0 in
       let cond_val = build_fcmp Fcmp.One cond zero "ifcond" builder in

       (* prepare first basic block *)
       let start_bb = insertion_block builder in
       let the_function = block_parent start_bb in

       let then_bb = append_block context "then" the_function in
       position_at_end then_bb builder;
       let then_val = codegen_stmt then_expr pass_manager in
       (* get an update of the then_bb since codegen may change the bb due to nested ifs *)
       let new_then_bb = insertion_block builder in

       let else_bb = append_block context "else" the_function in
       position_at_end else_bb builder;
       let else_val = codegen_stmt else_expr pass_manager in
       (* same as above *)
       let new_else_bb = insertion_block builder in

       (* emit merge block *)
       let merge_bb = append_block context "ifcont" the_function in
       position_at_end merge_bb builder;
       let incoming = [(then_val, new_then_bb); (else_val, new_else_bb)] in
       let phi = build_phi incoming "iftmp" builder in

       (* fix the if start bb *)
       position_at_end start_bb builder;
       ignore (build_cond_br cond_val then_bb else_bb builder);

       (* add conditional branches at end of then_bb and else_bb *)
       position_at_end new_then_bb builder; ignore (build_br merge_bb builder);
       position_at_end new_else_bb builder; ignore (build_br merge_bb builder);

       (* set point to end of merge_bb *)
       position_at_end merge_bb builder;
       phi
     end

       
       

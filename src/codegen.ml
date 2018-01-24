open Llvm

exception Error of string

let context = global_context ()
let the_module = create_module context "main"
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
         | '>' ->
            begin
              let i = build_fcmp Fcmp.Ugt lhs_val rhs_val "cmptmp" builder in
              build_uitofp i double_type "booltmp" builder
            end
         | '|' ->
            begin
              let zero = const_float double_type 0.0 in
              let a_bool = build_fcmp Fcmp.Ugt lhs_val zero "cmptmp_a" builder in
              let b_bool = build_fcmp Fcmp.Ugt rhs_val zero "cmptmp_b" builder in
              let or_res = build_or a_bool b_bool "ortmp" builder in
              build_uitofp or_res double_type "booltmp" builder
            end
         | '&' ->
            begin
              let zero = const_float double_type 0.0 in
              let a_bool = build_fcmp Fcmp.Ugt lhs_val zero "cmptmp_a" builder in
              let b_bool = build_fcmp Fcmp.Ugt rhs_val zero "cmptmp_b" builder in
              let and_res = build_and a_bool b_bool "andtmp" builder in
              build_uitofp and_res double_type "booltmp" builder
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
       (* get an update of the then_bb since codegen may change the bb due to nested iss *)
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
  | Astree.For (counter_name, start_, end_, step_size, body) ->
     let start_val = codegen_stmt start_ pass_manager in
     let preheader_bb = insertion_block builder in
     let the_function = block_parent preheader_bb in
     let loop_bb = append_block context "loop" the_function in

     ignore (build_br loop_bb builder);
     position_at_end loop_bb builder;

     (* build phi node for counter variable *)
     let variable = build_phi [(start_val, preheader_bb)] counter_name builder in
     let old_val =
       try Some (Hashtbl.find named_values counter_name) with Not_found -> None
     in
     Hashtbl.add named_values counter_name variable;

     (* build the body of the loop recursively *)
     ignore(List.iter (fun e -> ignore (codegen_stmt e pass_manager)) body);

     (* handle the step size of the loop *)
     let step_val = codegen_stmt step_size pass_manager in
     let next_var = build_fadd variable step_val "nextvar" builder in

     (* insert the end condition of the loop *)
     let end_cond = codegen_stmt end_ pass_manager in
     let zero = const_float double_type 0.0 in
     let end_cond = build_fcmp Fcmp.One end_cond zero "loopcond" builder in


     (* after loop basic block *)
     let loop_end_bb = insertion_block builder in
     let after_bb = append_block context "afterloop" the_function in
     ignore (build_cond_br end_cond loop_bb after_bb builder);
     position_at_end after_bb builder;

     (* add backwards branch to phi node *)
     add_incoming (next_var, loop_end_bb) variable;

     (* restore shadowed variable loop_counter *)
     begin match old_val with
     | Some old_val -> Hashtbl.add named_values counter_name old_val
     | None -> ()
     end;

     (* standard return type of loop *)
     const_null double_type
     
       

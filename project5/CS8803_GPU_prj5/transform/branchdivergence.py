class BranchDivergence:
    def apply(self, module):
        all_divergent_ids = set()
        for func in module.functions:
            if not func.blocks:
                continue

            #TODO :: Traverse the CFG to obtain a list of basic blocks to work with
                #Hint: The entry block is the first block in the function
                #Hint: See function.py and basicblock.py
            entry_bb = func.blocks[0]
            worklist = []
            queue = [entry_bb]
            visited = {entry_bb}

            sorted_succs_cache = {}
            while queue:
                bb = queue.pop(0)
                worklist.append(bb)

                if bb not in sorted_succs_cache:
                    sorted_succs_cache[bb] = sorted(bb._succs, key=lambda x: x.addr)

                for succ in sorted_succs_cache[bb]:
                    if succ not in visited:
                        visited.add(succ)
                        queue.append(succ)

            #TODO :: Construct global def-use table
                #Hint: See instruction.py and operand.py
                #Hint: Instruction.GetDef() and Instruction.GetUse() return registers
                #Hint: Tricky: a register name can store multiple potential definitions from multiple predecessor basic blocks
                #Hint: Use an iterative approach to handle loops.
            defs_in = {bb: {} for bb in worklist}
            defs_out = {bb: {} for bb in worklist}
            tainted_insts = set()

            changed = True

            # TODO :: Implement an iterative algorithm to propagate thread ID dependency across instructions
            while changed:
                changed = False

                for bb in worklist:
                    merged_defs_in = {}
                    for pred in bb._preds:
                        if pred in defs_out:
                            for reg, def_insts in defs_out[pred].items():
                                if reg not in merged_defs_in:
                                    merged_defs_in[reg] = set()
                                merged_defs_in[reg].update(def_insts)

                    if merged_defs_in != defs_in[bb]:
                        changed = True
                        defs_in[bb] = merged_defs_in

                    current_defs = {reg: defs.copy() for reg, defs in defs_in[bb].items()}
                    old_taint_count = len(tainted_insts)

                    for inst in bb.instructions:
                        if not inst.operands:
                            continue
                        is_tainted = False

                        # TODO :: Find thread ID dependent instructions
                        # Hint: opcode "S2R" is used to load thread ID into a register
                        if 'S2R' in inst.opcodes:
                            used_operand = inst.GetUses()[0]
                            if used_operand.IsThreadIdx:
                                is_tainted = True

                        for use in inst.GetUses():
                            if use.IsReg and use.Reg in current_defs:
                                defining_insts = current_defs[use.Reg]
                                if not tainted_insts.isdisjoint(defining_insts):
                                    is_tainted = True
                                    break

                        if is_tainted:
                            tainted_insts.add(inst)

                        defined_reg = inst.GetDef()
                        if defined_reg.IsReg:
                            current_defs[defined_reg.Reg] = {inst}

                    if current_defs != defs_out[bb]:
                        changed = True
                        defs_out[bb] = current_defs

                    if len(tainted_insts) > old_taint_count:
                        changed = True

            #TODO :: Update the list below with the branch divergence instruction IDs
            # Please donot change the name of this function
            # module.branch_divergence_insts.append(...)
            for inst in tainted_insts:
                if inst.IsBranch():
                    all_divergent_ids.add(inst._id)

            module.branch_divergence_insts.extend(sorted(list(all_divergent_ids)))

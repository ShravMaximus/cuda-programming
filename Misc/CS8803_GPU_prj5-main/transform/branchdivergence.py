class BranchDivergence:
    def apply(self, module):
        for func in module.functions:
            
            #TODO :: Traverse the CFG to obtain a list of basic blocks to work with 
                #Hint: The entry block is the first block in the function
                #Hint: See function.py and basicblock.py

            #TODO :: Construct global def-use table
                #Hint: See instruction.py and operand.py
                #Hint: Instruction.GetDef() and Instruction.GetUse() return registers
                #Hint: Tricky: a register name can store multiple potential definitions from multiple predecessor basic blocks 
                #Hint: Use an iterative approach to handle loops.

            #TODO :: Find thread ID dependent instructions 
                #Hint: opcode "S2R" is used to load thread ID into a register

            #TODO :: Implement an iterative algorithm to propagate thread ID dependency across instructions

            #TODO :: Update the list below with the branch divergence instruction IDs   
            # Please donot change the name of this function
            # module.branch_divergence_insts.append(...)
            
            raise NotImplementedError()

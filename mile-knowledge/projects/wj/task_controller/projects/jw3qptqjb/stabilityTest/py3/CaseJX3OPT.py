# -*- coding: utf-8 -*-
from CaseJX3SearchPanel import *

class CaseJX3OPT(CaseJX3SearchPanel):
    def __init__(self):
        super(CaseJX3OPT,self).__init__()
        self.BIN64_NAME = 'bin64_opt_trunk'
        
if __name__ == '__main__':
    obj_test = CaseJX3OPT()
    obj_test.run_from_IQB()

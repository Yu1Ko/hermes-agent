# -*- coding: utf-8 -*-

from CaseCommon import *
import os
import traceback
import psutil


class CaseSleep(CaseCommon):
    def __init__(self):
        super().__init__()

    def run_local(self, dic_args):
        nSleepTime=int(dic_args['nTime'])
        nMinites=int(nSleepTime/60)
        nSecond=nSleepTime-nMinites*60
        for i in range(nMinites):
            time.sleep(60)
            self.log.info(60)
        time.sleep(nSecond)


if __name__ == '__main__':
    obj_test = CaseSleep()
    obj_test.run_from_IQB()

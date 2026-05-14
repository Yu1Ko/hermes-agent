import subprocess

import psutil
import os
import logging
import configparser

def proc_exist(process_pid):
    pl = psutil.pids()
    for pid in pl:
        if pid == process_pid:
            return True
    return False

def get_last_line(filename):
    """
    get last line of a file
    :param filename: file name
    :return: last line or None for empty file
    """
    try:
        filesize = os.path.getsize(filename)
        if filesize == 0:
            return None
        else:
            with open(filename,'rb') as fp:
                offset = -8            # initialize offset
                while -offset < filesize:  # offset cannot exceed file size
                    fp.seek(offset, 2)   # read # offset chars from eof(represent by number '2')
                    lines = fp.readlines()   # read from fp to eof
                    if len(lines) >= 2:  # if contains at least 2 lines
                        return lines[-1]   # then last line is totally included
                    else:
                        offset *= 2    # enlarge offset
                fp.seek(0)
                lines = fp.readlines()
                return lines[-1]
    except FileNotFoundError:
        logging.error(filename + ' not found!')
        return None
    
def os_popen(cmd, readline = False) -> str:
    """
    执行popen, 返回结果
    """
    with os.popen(cmd) as p:
        try:
            if readline:
                return p.readline()
            else:
                return p.read()
        except:
            return 'decode error'

def subprocess_Popen(strCmd)-> str:
    pi = subprocess.Popen(strCmd, shell=True, stdout=subprocess.PIPE)
    res = pi.stdout.read()
    try:
        res = str(res, encoding='gbk')
    except:
        res = str(res, encoding='utf8')
    # if 'error' in res:
    # raise Exception(res)
    return res

class myConfigParser(configparser.ConfigParser):
    def __init__(self, defaults=None):
        configparser.ConfigParser.__init__(self, defaults=None)

    def optionxform(self, optionstr):
        return optionstr


def ini_read(path, iniconf):
    try:
        iniconf.read(path, encoding='utf8')
        return 'utf8'
    except:
        iniconf.read(path, encoding='GBK')
        return 'GBK'


def ini_write(path, iniconf, encoding):
    iniconf.write(open(path, 'w', encoding=encoding), space_around_delimiters=False)


def ini_get(section, key, path):
    iniconf = myConfigParser()
    encoding = ini_read(path, iniconf)
    return iniconf.get(section, key)


def ini_set(section, key, val, path):
    listSec = ini_getSections(path)
    if section not in listSec:
        ini_addSection(section, path)
    iniconf = myConfigParser()
    encoding = ini_read(path, iniconf)
    if type(val) == int:
        val = str(val)
    iniconf.set(section, key, val)
    return ini_write(path, iniconf, encoding)

def ini_getOptions(section, path):
    iniconf = myConfigParser()
    encoding = ini_read(path, iniconf)
    if section not in iniconf.sections():
        return None
    return iniconf.options(section)


def ini_getSections(path):
    iniconf = myConfigParser()
    encoding = ini_read(path, iniconf)
    return iniconf.sections()


def ini_removeSection(section, path):
    listSec = ini_getSections(path)
    if section not in listSec:
        return
    iniconf = myConfigParser()
    encoding = ini_read(path, iniconf)
    iniconf.remove_section(section)
    return ini_write(path, iniconf, encoding)


def ini_addSection(section, path):
    listSec = ini_getSections(path)
    if section in listSec:
        return
    iniconf = myConfigParser()
    encoding = ini_read(path, iniconf)
    iniconf.add_section(section)
    return ini_write(path, iniconf, encoding)
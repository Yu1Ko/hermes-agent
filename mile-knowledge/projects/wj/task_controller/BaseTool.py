
# ------------------ini----------------------
# -*- coding: utf-8 -*-

# 目前本ini接口只支持GBK编码和utf8编码（不包括utf8-BOM）的配置文件
import configparser
import socket


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

#动态导入脚本模块
list_module_name=[]
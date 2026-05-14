# -*- encoding=utf8 -*-
__author__ = "kingsoft"

from airtest.core.api import *
from airtest.cli.parser import cli_setup

if not cli_setup():
    auto_setup(__file__, logdir=True, devices=["Android:///",], project_root="D:/GitHubProject/jw3qptqjb/jxsjorigin/Report")


# script content
print("start...")

touch(Template(r"tpl1763348761515.png", record_pos=(-0.356, -0.825), resolution=(1080, 2374)))


# generate html report
# from airtest.report.report import simple_report
# simple_report(__file__, logpath=True)
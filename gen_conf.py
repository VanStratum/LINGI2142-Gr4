#! /usr/bin/env python

from os import listdir, getcwd, mkdir, chmod, path
import stat
import sys
import json
from re import sub
from mako.template import Template
from argparse import FileType, ArgumentParser
from shutil import copyfile

CURDIR = getcwd()
TEMPLATES_DIR = '%s/templates/'%CURDIR
CONFIG_DIR = '%s/network_cfg/'%CURDIR

def generate_config(inp, template, outp):
    with open(inp, 'r') as fp:
        data = json.loads(fp.read())
    template = Template(filename=template)
    with open(outp, 'w') as f:
        f.write(template.render(data=data))


templates_content = listdir(TEMPLATES_DIR)

# Get all template files
templates = [f for f in templates_content if '.mako' in f]

# Get config file for each router
config_files = [f for f in templates_content if '.json' in f]

exe = 0
for t in templates:
    print('=> Template: %s'%t)
    for cf in config_files:
        inf = '%s%s'%(TEMPLATES_DIR,cf)
        name = '%s'%sub('.json','',cf)
        if name not in listdir(CONFIG_DIR):
            mkdir('%s%s'%(CONFIG_DIR,name))

        if 'ospf' in t:
            rp = '%s/%s_ospf.conf'%(name,name)
            exe = 0
        elif 'zebra' in t:
            rp = '%s/%s_zebra.conf'%(name,name)
            exe = 0
        elif 'start' in t:
            rp = '%s_start'%name
            exe = 1
        elif 'boot' in t:
            rp = '%s_boot'%name
            exe = 1

        out = '%s%s'%(CONFIG_DIR,rp)

        #print('in: %s'%inf)
        print('%s generated'%out)
        generate_config(inf, '%s%s'%(TEMPLATES_DIR,t), out)
        if exe:
            chmod(out,stat.S_IXUSR|stat.S_IXGRP|stat.S_IWUSR|stat.S_IXOTH|stat.S_IRUSR)

for i in [j for j in templates_content if '.conf' in j]:
    print(i)
    for k in listdir(CONFIG_DIR):
        dir_item = '%s%s'%(CONFIG_DIR,k)
        if path.isdir(dir_item):
            copyfile('%s%s'%(TEMPLATES_DIR,i), '%s/%s'%(dir_item,i))
 

#! /usr/bin/python3

import sys
import argparse

version = "Ver. 1.0";

#
# Argument Parser
#

ap = argparse.ArgumentParser(description='verilog $readmemb file by objdump to Verilog $readmemh file')
ap.add_argument('in_file', nargs='+', help='verilog $readmemb file')
ap.add_argument('-s', '--split', action='store_true', help='Split prog and data initialize files')
ap.add_argument('-d', '--debug', action='store_true', help='Debug mode')
ap.add_argument('--data_base', type=int, default=0x00100000, help='Data memory base addr (default:0x00100000).')

args = ap.parse_args()

split_mode = args.split
debug_mode = args.debug

in_file = args.in_file[0]
verilog_index = in_file.find(".verilog")
if verilog_index == -1:
    verilog_file = in_file + ".verilog"
    if split_mode:
        out_prog_file = "prog.mif"
        out_data_file = "data.mif"
    else:
        out_file = in_file + ".mif"
else:
    verilog_file = in_file
    if split_mode:
        out_prog_file = "prog.mif"
        out_data_file = "data.mif"
    else:
        out_file = in_file[0:verilog_index] + ".mif"

line_no = 0  # Line number
text_seg = 0  # default segment
data_seg = args.data_base
core = []  # Memory image

#
# Intput
#

address = 0

ifp = open(verilog_file)

for line in ifp:
    line_no += 1

    if line[0] == "@":
        new_address = int(line[1:], 16)  # 1- char
        print("Check @address boundary, ", format(address, '08X'), ':', format(new_address, '08X'))
        address = new_address
        if debug_mode == True:
            print(line, address)

    else:
        line_token = line.split()
        if debug_mode:
            print(line_token)
        i = 0
        word = ''
        for token in line_token:
            if debug_mode:
                print(token)
            word += token
            i += 1
            if i == 4:
                core.append([format(address, '08X'), word])
                word = ''
                i = 0
                address += 4

#    line = ifp.readline()

ifp.close()

if debug_mode:
    print(core)

#
# Output
#

if split_mode:
    opfp = open(out_prog_file, "w")
    odfp = open(out_data_file, "w")
else:
    ofp = open(out_file, "w")

for (address, dat) in core:
    if split_mode:
        if int(address, 16) >= data_seg:
            odfp.write(dat + " // " + address + "\n")
        else:
            opfp.write(dat + " // " + address + "\n")
    else:
        ofp.write(dat + " // " + address + "\n")

if split_mode:
    opfp.close()
    odfp.close()
else:
    ofp.close()

#!/bin/sh

# 
# Vivado(TM)
# runme.sh: a Vivado-generated Runs Script for UNIX
# Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
# 

if [ -z "$PATH" ]; then
  PATH=/home/chris/Vivado/2023.1/ids_lite/ISE/bin/lin64:/home/chris/Vivado/2023.1/bin
else
  PATH=/home/chris/Vivado/2023.1/ids_lite/ISE/bin/lin64:/home/chris/Vivado/2023.1/bin:$PATH
fi
export PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
  LD_LIBRARY_PATH=
else
  LD_LIBRARY_PATH=:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

HD_PWD='/home/chris/Dropbox/Masters/Design of Digital Systems/Assignments/DigitalSystem/Assignment_1/doc/assignment_1/assignment_1.runs/synth_1'
cd "$HD_PWD"

HD_LOG=runme.log
/bin/touch $HD_LOG

ISEStep="./ISEWrap.sh"
EAStep()
{
     $ISEStep $HD_LOG "$@" >> $HD_LOG 2>&1
     if [ $? -ne 0 ]
     then
         exit
     fi
}

EAStep vivado -log gcd_tb.vds -m64 -product Vivado -mode batch -messageDb vivado.pb -notrace -source gcd_tb.tcl

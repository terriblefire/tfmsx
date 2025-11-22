UNAME := $(shell uname)
XILINXENV:=
SRCROOT:=$(abspath $(PWD)/../../)
BRDROOT:=$(subst $(SRCROOT),,$(abspath $(PWD)))
DOCKERIMAGE:=terriblefire78/xilinx:latest

ifneq ($(UNAME), Linux)
      DOCKERHASH:=$(shell docker images -q $(DOCKERIMAGE) )

      ifeq ($(DOCKERHASH), )
      	    $(shell docker build .. -t xilinx --platform linux/amd64)
      endif
      
      XILINXENV=docker run --rm --platform linux/amd64 -v $(SRCROOT):/host -w /host/$(BRDROOT) $(DOCKERIMAGE) 
endif

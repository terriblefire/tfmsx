UNAME := $(shell uname)
XILINXENV:=
SRCROOT:=$(abspath $(PWD)/../../)
BRDROOT:=$(subst $(SRCROOT),,$(abspath $(PWD)))
DOCKERIMAGE:=xilinx

ifneq ($(UNAME), Linux)
      DOCKERHASH:=$(shell docker images -q $(DOCKERIMAGE) )

      ifeq ($(DOCKERHASH), )
      	    $(shell docker build .. -t xilinx --platform linux/amd64)
      endif
      
      XILINXENV=docker run --rm  -v $(SRCROOT):/host -w /host/$(BRDROOT) -it $(DOCKERIMAGE) 
endif

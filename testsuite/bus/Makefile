SOURCES:= $(shell find . -name 'test_*.v')
TESTOBJS=$(subst .v,.tb,$(SOURCES))
TARGETS=$(subst .v,.vcd,$(SOURCES))

RTLFOLDER:=../../rtl
RTLSOURCES:=$(RTLFOLDER)/tfmsx_top.v $(RTLFOLDER)/clocks.v $(RTLFOLDER)/rp5c01a.v

# Force removal of VCDs so tests always run fresh
all: force $(TARGETS) summary

include ../Makefile.inc

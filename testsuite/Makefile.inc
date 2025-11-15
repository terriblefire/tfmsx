IV:=iverilog
SUPPORT:=../rtl/
RTLFOLDER:=../../rtl

XILINXMODS:= $(SUPPORT)/FDCPE.v $(SUPPORT)/FDCP.v $(SUPPORT)/PULLUP.v $(SUPPORT)/KEEPER.v
ICEMODS:=$(SUPPORT)/cells_sim.v

.PHONY: force summary

%.tb: %.v $(RTLSOURCES) $(RTLVINCS)
	$(IV) -DDEBUG=1 -o $(@)  -I$(RTLFOLDER) $(RTLSOURCES) $< $(XILINXMODS) $(ICEMODS)

%.vcd: %.tb
	timeout 60 ./$< || (rm -f $@ && exit 1)

# Force removal of VCDs so tests always run fresh
force:
	@rm -f *.vcd

summary:
	@echo ""
	@echo "=== Test Results ==="
	@total=$$(ls -1 test_*.v 2>/dev/null | wc -l | tr -d ' '); \
	passed=$$(ls -1 *.vcd 2>/dev/null | wc -l | tr -d ' '); \
	failed=$$(expr $$total - $$passed); \
	echo "Total tests:  $$total"; \
	echo "Passed tests: $$passed"; \
	echo "Failed tests: $$failed"; \
	echo ""; \
	if [ $$failed -ne 0 ]; then \
		echo "Failed tests:"; \
		for v in test_*.v; do \
			vcd=$${v%.v}.vcd; \
			if [ ! -f "$$vcd" ]; then \
				echo "  $$v"; \
			fi; \
		done; \
		echo ""; \
		echo "=== Failed Test Output ==="; \
		for v in test_*.v; do \
			vcd=$${v%.v}.vcd; \
			tb=$${v%.v}.tb; \
			if [ ! -f "$$vcd" ]; then \
				echo ""; \
				echo "--- $$v ---"; \
				timeout 60 ./$$tb 2>&1 || true; \
			fi; \
		done; \
		exit 1; \
	else \
		echo "All tests passed!"; \
	fi

clean:
	rm -f *.tb *.vcd

distclean:
	rm -f  *~

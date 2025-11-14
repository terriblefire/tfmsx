.PHONY: jeds
BOARDS:=$(shell cat ./boards.txt)
GITVERSION:=`git rev-parse --short HEAD`
DATESTRING:=`date +"%Y_%m_%d"`
GITREPO:=$(shell basename `git rev-parse --show-toplevel`)
RELEASE_PACKAGE=$(GITREPO)_$(DATESTRING)_$(GITVERSION).zip

.PHONY: $(BOARDS)
all: clean jeds
jeds:
	@- $(foreach BOARD,$(BOARDS), cd $(BOARD) ; make )
zip: jeds
	@- $(foreach BOARD,$(BOARDS), cd $(BOARD) ; zip ../$(RELEASE_PACKAGE) *.jed )
clean: 
	$(RM) $(RELEASE_PACKAGE)
	@- $(foreach BOARD,$(BOARDS), make -C $(BOARD) clean;)
	$(RM) *.zip
distclean: 
	@- $(foreach BOARD,$(BOARDS), make -C $(BOARD) distclean;)

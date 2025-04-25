install-%: # run the installation for a specific step
	@echo "Installing: $*"
	./bin/ih-setup install core $* -f
.PHONY: install-%

help:
	@echo "---------------------"
	@echo "Makefile for ih-setup"
	@echo ""
	@echo "useful for local development"
	@echo "---------------------"
	@echo "Usage:"
	@echo ""
	@echo "  make install-<step>"
	@echo "      description: Test the installation of a step"
	@echo "      example: make install-github"
	@echo ""
.PHONY: help

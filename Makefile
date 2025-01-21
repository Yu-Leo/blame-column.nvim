all: format lint

STYLUA ?= stylua

.PHONY: lint_stylua
lint_stylua:
	${STYLUA} --color always --check lua

.PHONY: lint_luacheck
lint_luacheck:
	luacheck lua

.PHONY: lint 
lint: lint_luacheck lint_stylua

.PHONY: format 
format:
	${STYLUA} lua

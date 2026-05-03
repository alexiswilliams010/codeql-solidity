# Makefile for codeql-solidity setup and development

# Configuration
CODEQL_HOME ?= $(HOME)/codeql-home
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  CODEQL_PLATFORM = osx64
else ifeq ($(UNAME_S),Linux)
  CODEQL_PLATFORM = linux64
else
  CODEQL_PLATFORM = win64
endif
CODEQL_BUNDLE_URL = https://github.com/github/codeql-action/releases/latest/download/codeql-bundle-$(CODEQL_PLATFORM).tar.gz

.PHONY: help codeql-cli build pack clean test install

help: ## Show this help message
	@echo "Available targets:"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

codeql-cli: ## Download and extract CodeQL CLI
	@echo "Downloading CodeQL CLI..."
	@mkdir -p $(CODEQL_HOME)
	@cd $(CODEQL_HOME) && \
		if [ ! -d "codeql" ]; then \
			echo "Downloading from $(CODEQL_BUNDLE_URL)"; \
			curl -fL -o codeql-bundle.tar.gz "$(CODEQL_BUNDLE_URL)" || \
			(echo "Failed to download CodeQL CLI from $(CODEQL_BUNDLE_URL)"; exit 1); \
			echo "Extracting CodeQL CLI..."; \
			tar -xzf codeql-bundle.tar.gz; \
			rm -f codeql-bundle.tar*; \
		else \
			echo "CodeQL CLI already exists"; \
		fi

install: codeql-cli ## Install CodeQL CLI to system PATH
	@if [ ! -f "$(CODEQL_HOME)/codeql/codeql" ]; then \
		echo "CodeQL CLI not found. Run 'make codeql-cli' first."; \
		exit 1; \
	fi
	@case "$$SHELL" in \
		*/zsh) RC="$$HOME/.zshrc" ;; \
		*/bash) RC="$$HOME/.bashrc" ;; \
		*) echo "Unknown shell ($$SHELL). Add this to your shell rc manually:"; \
		   echo '    export PATH="$(CODEQL_HOME)/codeql:$$PATH"'; exit 0 ;; \
	esac; \
	LINE='export PATH="$(CODEQL_HOME)/codeql:$$PATH"'; \
	touch "$$RC"; \
	if grep -Fqx "$$LINE" "$$RC"; then \
		echo "CodeQL CLI already on PATH in $$RC"; \
	else \
		printf '\n%s\n' "$$LINE" >> "$$RC"; \
		echo "CodeQL CLI added to PATH in $$RC"; \
	fi; \
	echo "Restart your shell or run: source $$RC"

build: ## Build the Solidity extractor
	@echo "Building Solidity extractor..."
	@cd extractor && cargo build --release

pack: build ## Create the extractor pack
	@echo "Creating extractor pack..."
	@./scripts/create-extractor-pack.sh
	@echo "Extractor pack created"

test: ## Test the extractor
	@echo "Testing the extractor..."
	@cd extractor && cargo test

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@cd extractor && cargo clean
	@rm -rf extractor-pack
	@rm -rf ql/lib/solidity.dbscheme*
	@rm -rf ql/lib/codeql/solidity/ast/internal/TreeSitter.qll

# Makefile for codeql-solidity setup and development

# Configuration
CODEQL_HOME ?= $(HOME)/codeql-home
PLATFORM ?= $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH ?= $(shell uname -m | sed 's/x86_64/64/' | sed 's/aarch64/64/')
CODEQL_PLATFORM = $(PLATFORM)$(ARCH)
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
			curl -L -o codeql-bundle.tar.gz "$(CODEQL_BUNDLE_URL)" || \
			(echo "❌ Failed to download CodeQL CLI. Check the URL and try again."; exit 1); \
			echo "📦 Extracting CodeQL CLI..."; \
			tar -xzf codeql-bundle.tar.gz; \
			rm -f codeql-bundle.tar*; \
		else \
			echo "✅ CodeQL CLI already exists"; \
		fi

install: codeql-cli ## Install CodeQL CLI to system PATH
	@echo "🔧 Installing CodeQL CLI to system PATH..."
	@if [ -f "$(CODEQL_HOME)/codeql/codeql" ]; then \
		if [ -f ~/.zshrc ]; then \
			echo 'export PATH="$(CODEQL_HOME)/codeql:$$PATH"' >> ~/.zshrc; \
			echo "✅ CodeQL CLI added to PATH in ~/.zshrc"; \
			source ~/.zshrc; \
		else \
			echo 'export PATH="$(CODEQL_HOME)/codeql:$$PATH"' >> ~/.bashrc; \
			echo "✅ CodeQL CLI added to PATH in ~/.bashrc"; \
			source ~/.bashrc; \
		fi \
	else \
		echo "❌ CodeQL CLI not found. Run 'make setup' first."; \
		exit 1; \
	fi

build: ## Build the Solidity extractor
	@echo "🔨 Building Solidity extractor..."
	@cd extractor && cargo build --release

pack: build ## Create the extractor pack
	@echo "Creating extractor pack..."
	@./scripts/create-extractor-pack.sh
	@echo "✅ Extractor pack created!"

test: ## Test the extractor
	@echo "🧪 Testing the extractor..."
	@cd extractor && cargo test

clean: ## Clean build artifacts
	@echo "🧹 Cleaning build artifacts..."
	@cd extractor && cargo clean
	@rm -rf extractor-pack
	@rm -rf ql/lib/solidity.dbscheme*
	@rm -rf ql/lib/codeql/solidity/ast/internal/TreeSitter.qll

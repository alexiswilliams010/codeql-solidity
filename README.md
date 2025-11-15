# codeql-solidity

CodeQL support for the Solidity programming language

## Install

Use the Makefile commands to install the codeql cli and add it to your PATH:

```bash
make install
```

To work on the Solidity library files, you will also need to install the `qlpack` dependencies using the CodeQL CLI:

```bash
codeql pack install
```

When installing the required dependencies, make sure the CodeQL VSCode extension has not already installed the packs. If they have been pre-installed, remove them so the CLI can install successfully:

```
Linux install path for VSCode CodeQL packs: ~/codeql-home/codeql/qlpacks/codeql
```

## Extract Solidity into a top-level QL Library

Using tree-sitter, we are able to convert Solidity into a QL library using just the standard extract that exists in CodeQL with minimal configuration.
To generate the `TreeSitter.qll` file using the extractor, run:

```bash
make pack
```

Note this only needs to be run if the underlying tree sitter bindings have changed, at which point `TreeSitter.qll` will need to be regenerated along with all the code databases.

## Generate Database

To parse Solidity files and generate a codeql database, run the following:

```bash
codeql database create -l solidity --overwrite --search-path extractor-pack/ --source-root <path_to_sol_files> <db_name>
```

## Run Queries

Once you have your database created, you can run `.ql` queries against it by running:

```bash
codeql query run <path_to_query> -d <path_to_database>
```

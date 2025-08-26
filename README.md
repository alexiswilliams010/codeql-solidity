# codeql-solidity

CodeQL support for the Solidity programming language

## Install

Use the Makefile commands to install the codeql cli and add it to your PATH:

```bash
make install
```

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

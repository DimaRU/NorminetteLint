# norminette linter for 42 schools, Xcode compatible

## Install:

Requires Xcode 12.
Build and copy executable to the "/usr/local/bin" for example.

## Usage

```
USAGE: norminettelint [<path> ...] [--version] [--rules-list] [--warnings] [--config <path>]

ARGUMENTS:
  <path>                  Path to directory or file. 

OPTIONS:
  -v, --version           Display version of the remote nominette server. 
  --rules-list            Display rules list. 
  -w, --warnings          Downgrades errors to warnings. 
  -c, --config <path>     The path to the configuration file. 
        By default, .norminettelint.yml searched on current directory and then
        on home directory.
  --version               Show the version.
  -h, --help              Show help information.
```

####Examples:

```
norminettelint
```
Runs on the current folder and any subfolder.

```
norminettelint filename.[c/h]
```
Runs on the given filename(s).

```
norminetteint -w
```
Threat errors as warnings.

## Configuration file example:
```yml
hostname: norminette.42network.org
user: guest
password: guest
warnings: false
disabledRules: []
```
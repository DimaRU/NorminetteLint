# 42 school norminette for Xcode

## Install:

Download form releases and copy executable to the "/usr/local/bin" or to the home directory (~) in school environment.
Create `.norminettelint.yml` configuation file in home directory or in the project directory.

## Build:

Requires Xcode 12.

## Usage

```
USAGE: norminettelint [<path> ...] [--setup-xcode-proj] [--remote] [--rules-list] [--warnings] [--config <path>] [--exclude <file> ...]

ARGUMENTS:
  <path>                  Path to directory or file.

OPTIONS:
  -s, --setup-xcode-proj  Add norminettelint run script to Xcode project
  --remote                Display version of the remote nominette server.
  --rules-list            Display rules list.
  -w, --warnings          Downgrade errors to warnings.
  -c, --config <path>     The path to the configuration file.
        By default, .norminettelint.yml searched on current directory and then on home directory.
  -x, --exclude <file>    Exclude file from check.
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

```
norminetteint -s project
```
Setup Xcode project in `project` folder for check with norminettelint. Also set indent using tabs and `-Wall`, `-Wextra` warning flags

```
norminetteint -x main.c -x ft_proj.h 
```
Exclude main.c and ft_proj.h from check.


## Configuration file example:
```yml
hostname: norminette.42network.org
user: guest
password: guest
warnings: false
specialRules: []
```

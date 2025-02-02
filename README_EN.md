<h1 align="center">Axis (still in alpha ⚠️)</h1>

**Axis** is a command-line tool for standardizing commit messages in projects using some versioning tool like Git. It allows the user to define structured commit messages by using a YAML configuration file.

## Installation
Currently, there is no binary available, so you must compile the project from source.

### Prerequisites
- Ocaml
- Dune
- Packages: [Core](https://ocaml.org/p/core/latest), [Yaml](https://ocaml.org/p/yaml/latest/doc/Yaml/index.html) e [Cmdliner](https://ocaml.org/u/f06857371084eb01bbf1461eed1e6df0/cmdliner/1.0.4/doc/Cmdliner/index.html)

Then, you can do:

```
git clone <url>
dune build
dune install
```

## Features
Currently, the program has only one command, which is formatting. But how does it work?

Axis reads a file in your terminal's current directory (i.e., the output of the `pwd` command in Linux) called `.axis.yaml`, where all the formatting settings for your commit message are stored. The expected format is:

```yaml
variables:
  variable_name: value
  another_variable: another_value

templates:
  Fix:
    pattern: "{variable_name} {message}. No further maintenance"
    prefix: "[FIX]"
    suffix: " Done by <some work team name>"
```

Breaking down this file in parts, we have:

#### Variables
A way to store a value for sharing between patterns or speeding up the writing process. The field where variables are declared must be named `variables`, exactly as shown in the example.

#### Templates
Fully customizable message patterns. Each template must have:
- A name, to be referenced when used;
- A message pattern, named `pattern`, which represente how your message will be formatted;
- A prefix for your message, called `prefix`;
- A suffix for your message, called `suffix`;

Templates work very simply: everything inside curly braces is a **variable**. The only exception is `{message}`, which representes the user-defined message that will be provided when invoking axis.

Not being a surprise, variables should not be declared using config file keywords, such as `message` or `pattern`.

## Contribution

Contributions are very welcome. To contribute:

1. Fork the repo.
2. Create a branch for your feature/fix.
3. Make the necessary changes and commit it (if possible, using axis).
4. Submit a pull request.

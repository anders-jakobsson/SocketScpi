Introduction
============

NOTE!!! This is currently under development, don't use it!!!

SocketScpi is a Julia package that enables [SCPI](https://www.ivifoundation.org/docs/scpi-99.pdf) communication with an instrument over TCP sockets. By relying on Julia [Sockets](https://docs.julialang.org/en/v1/stdlib/Sockets/) from the standard library, no additional drivers, e.g., VISA drivers are needed.

The following types are exported.

* Instrument
* ScpiString

`Instrument` is an object that encapsulates the properties needed to communicate with an instrument. This includes its address and port, as well as default timeout. An `Instrument` object is callable. Instrument communication is performed by calling the object with an `ScpiString`. A
`ScpiString` is a string that is formated as an [SCPI](https://www.ivifoundation.org/docs/scpi-99.pdf) command. A command can be made up of multiple sub-commands separated by a semicolon.

Installation
------------

Note! This package is not yet official, and must be installed from its GitHub repository. To do this, do the following <TODO! ADD URL>:

```julia
using Pkg
Pkg.add("<package-url>")
```

Usage
-----

Setting up instrument communication is quite simple. First, create an `Instrument` object for each instrument, for example:

```julia
using SocketScpi

spec = Instrument("192.168.0.56", port=5025, timeout=5)
```

The `port` and `timeout` arguments are optional, and default to `5025` and `10` respectively. For additional information, please see [The `Instrument` type](#the-instrument-type) section. Once an `Instrument` object has been created, simply __call__ the object with the SCPI command string as in:

```julia
spec(":FREQUENCY:CENTER 1GHz")
```

So in summary, you can have instrument communication up and running with three lines of code.

Obviously there are more features and options that those mentioned above, as will be described in the following sections.

The `Instrument` type
=====================

The `ScpiString` type
=====================

When an `Instrument` object is called with a string, as shown in the [Usage](#usage) section, the string is implicitly converted to a `ScpiString` object. The string can also be created explicitly by calling its constructor method:

```julia
ScpiString(xs::AbstractString)
ScpiString(xs...)
scpi"<command-string>"
```

The input string `xs` is pre-procecced and validated. In case of additional string arguments, each is converted to an `ScpiString` and then concatenated as sub-commands, see [Concatenation](#concatenation). Every argument may also contain multiple sub-commands on their own. Note that while a SCPI command is terminated with a newline '\n', it is not neccessary to terminate `xs` with a newline as this will be added automatically when sending the command. In fact, any leading or trailing newline or whitespace will be removed by the constructor. At the same time, no newline character is allowed within a command.

Some examples of creating `ScpiString`'s are given below.

```julia
cmd1 = ScpiString("*IDN?");
cmd2 = scpi"OUTPUT ON";
cmd3 = ScpiString(":FREQ:CENT 1GHz", "SPAN 100MHz", ":INIT:CONT?", ":TRAC:CLE ALL")
```

A benefit of explicitly creating an `ScpiString` is that printing it reveal some valuable visual information about it. For `cmd3` in the example above, the following is printed:

```
SCPI string with 4 commands of which one is a query
 :FREQ:CENT 1GHz
       SPAN 100MHz
 :INIT:CONT?
 :TRAC:CLE ALL
```

The printout indents every sub-command to its active anchor. The second sub-command 'SPAN 100MHz' lacks a leading colon, meaning it is anchored to the previous sub-command, or ':FREQ:'. This allows to visually inspect the commands for correctness. For example, if the last sub-command was accidently prefixed with a semicolon instead of a colon, it would get anchored to ':INIT:'. This would print as

```
SCPI string with 4 commands of which one is a query
 :FREQ:CENT 1GHz
       SPAN 100MHz
 :INIT:CONT?
       TRAC:CLE ALL
```

Concatenation
-------------

Just like normal Julia strings, `ScpiStrings` can be concatenated by multiplication. Each string is treated as a sub-command, and a semicolon is added between them.

```julia
cmd1 * cmd2
```
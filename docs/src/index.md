Introduction
============

SocketScpi is a Julia package that enables [SCPI](https://www.ivifoundation.org/docs/scpi-99.pdf) communication with an instrument over TCP sockets. By relying on Julia [Sockets](https://docs.julialang.org/en/v1/stdlib/Sockets/) from the standard library, no additional drivers, e.g., VISA drivers are needed.

The following types are exported.

* Instrument
* ScpiString

`Instrument` is an object that encapsulates the properties needed to communicate with an instrument. This includes its address and port, as well as default timeout. An `Instrument` object is callable. Instrument communication is performed by calling the object with an `ScpiString`. A
`ScpiString` is a string that is formated as an [SCPI](https://www.ivifoundation.org/docs/scpi-99.pdf) message. A message can be made up of multiple commands separated by semicolons.


SCPI basics
-----------

SCPI defines a protocol for messages sent to, or received from, the instrument. Messages are made up of commands. Commands sent to the instrument can be divided into three types:

      * Control commands
      * Query commands
      * Event commands

_Control commands_ alters a setting or state in the instrument. These commands take one or more arguments. _Query commands_ asks the instrument to return the current value of a setting. These commands may also take arguments to further specify what to return. Most control command have a corresponding query command. _Event commands_ triggers the instrument to perform an action. These commands do not take arguments, and do not have a query form.

Commands can also be divded into two other types, _common commands_ and _subsystem commands_. _Common commands_ are easy to identify because they have a leading asterisk followed by three letters. These commands are common to all SCPI instruments and control high level functions. Examples include "*IDN?" and "*RST". _Subsystem commands_ on the other hand target specific functionality within the instrument. Examples include ":CONTrol" and ":SYSTem".



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

The `port` and `timeout` arguments are optional, and default to `5025` and `10` respectively. For additional information, please see [The Instrument type](#the-instrument-type) section. Once an `Instrument` object has been created, simply __call__ the object with the SCPI command string as in:

```julia
spec(":FREQUENCY:CENTER 1GHz")
```

So in summary, you can have instrument communication up and running with three lines of code.

Obviously there are more features and options that those mentioned above, as will be described in the following sections.

The Instrument type
===================

```@docs
Instrument(::AbstractString)
```


The ScpiString type
===================

When an `Instrument` object is called with a string, as shown in the [Usage](#usage) section, the string is implicitly converted to a `ScpiString` object. The string can also be created explicitly by calling its constructor method:

```@docs
ScpiString
```

A benefit of explicitly creating an `ScpiString` is that printing it reveal some valuable visual information about it. The last example above illustrates this. The printout indents every sub-command to its active anchor. The second sub-command 'SPAN 100MHz' lacks a leading colon, meaning it is anchored to the previous sub-command, or ':FREQ:'. This allows to visually inspect the commands for correctness. For example, if the last sub-command was accidently prefixed with a semicolon instead of a colon, it would get anchored to ':INIT:'. This would 
instead print as:

```
SCPI string with 4 commands of which one is a query
 :FREQ:CENT 1GHz
       SPAN 100MHz
 :INIT:CONT?
       TRAC:CLE ALL
```

It is clear by visual inspection that this is not the intended behavior, making it
easier to correct erraneous command sequences.

Concatenation
-------------

Just like normal Julia strings, `ScpiStrings` can be concatenated by multiplication. Each string is treated as a sub-command, and a semicolon is added between them.

```@docs
*(::ScpiString,::ScpiString)
```

Introduction
============

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

The `port` and `timeout` arguments are optional, and default to `5025` and `10` respectively. For additional information, please see [The `Instrument` type](#the-instrument-type) section. Once an `instrument` object has been created, simply __call__ the object with the SCPI command string as in:

```julia
spec(":FREQUENCY:CENTER 1GHz")
```

So in summary, you can have instrument communication up and running with three lines of code.

Obviously there are more features and options that those mentioned above, as will be described in the following sections.




The `Instrument` type
=======================




# The `ScpiString` type

For example:

```:FREQUENCY:START 1MHZ; STOP 2MHz```

Since the second sub-command lacks a leading colon, it implicitly inherits the root of the previous sub-command, in this case `:FREQUENCY:`. 
# Introduction

SocketScpi is a Julia package that enables [SCPI](https://www.ivifoundation.org/docs/scpi-99.pdf) communication with an instrument over TCP sockets. By relying on Julia [Sockets](https://docs.julialang.org/en/v1/stdlib/Sockets/) from the standard library, no additional drivers, e.g., VISA drivers are needed.

The following types are exported.

* Instrument
* ScpiString

`Instrument` is an object that encapsulates the properties needed to communicate with an instrument. This includes its address and port, as well as default timeout. An `Instrument` object is callable. Instrument communication is performed by calling the object with an `ScpiString`. A 
`ScpiString` is a string that is formated as an [SCPI](https://www.ivifoundation.org/docs/scpi-99.pdf) command. A command can be made up of multiple sub-commands separated by a semicolon. 


## The `Instrument` type

## The `ScpiString` type

For example:

```:FREQUENCY:START 1MHZ; STOP 2MHz```

Since the second sub-command lacks a leading colon, it implicitly inherits the root of the previous sub-command, in this case `:FREQUENCY:`. 
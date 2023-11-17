# Introduction

SocketScpi is a Julia package that enables [SCPI](https://www.ivifoundation.org/docs/scpi-99.pdf) communication with an instrument over TCP sockets. By relying on Julia [Sockets](https://docs.julialang.org/en/v1/stdlib/Sockets/) from the standard library, no additional drivers, e.g., VISA drivers are needed.

The following types are exported.

* Instrument
* ScpiString

`Instrument` is an object that encapsulates the properties needed to communicate with an instrument. This includes its address and port, as well as default timeout. An `Instrument` object is callable. Instrument communication is performed by calling the object with an `ScpiString`.

`ScpiString` is a string that is formated as an SCPI command. 

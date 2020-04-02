# Coding challenge

## Contents

* [About Memcached](#memcached)
* [Installation](#installation)
* [Usage](#usage)
  * [Server](#server)
  * [Client demo and sample commands](#client-demo)
  * [Tests](#test)
* [Further resources](#further-resources)

## About Memcached

Memcached is a high-performance, distributed memory object caching system, generic in nature, but originally intended for use in speeding up dynamic web applications by alleviating database load. You can think of it as a short-term memory for applications.

Memcached is made up of four main components. These components allow the client and the server to work together in order to deliver cached data as efficiently as possible:
* **Client software** - which is given a list of available Memcached servers
* **A client-based hashing algorithm** - chooses a server based on the “key”
* **Server software** - stores values and their keys into an internal hash table
* **LRU** - determines when to throw out old data or reuse memory

## Installation
You need *Ruby v2.0.0* installed.

## Usage
### Server
`ruby server.rb <socket_address> <socket_port>`
  
  Optional <socket_address> and <socket_port> arguments determine the address where the server will be listening. `localhost:9999` is assigned by default.

### Client demo and sample commands

  * `ruby client_demo.rb <socket_address> <socket_port>` is a short demonstration of a client-server interaction, with their corresponding actions and commands sent and received.
  * `ruby client.rb <socket_address> <socket_port>` allows to send requests to server and receive server responses through the command line.
  
  Optional <socket_address> and <socket_port> arguments determine the address for the TCP socket of the client. `localhost:9999` is assigned by default.
  
  
### Tests

## Resources
*  [Memcached wiki](https://github.com/memcached/memcached/wiki)
*  [About Memcached](http://memcached.org/about)
*  [Full list of commands](http://lzone.de/cheat-sheet/memcached)
*  [The protocol specification](https://github.com/memcached/memcached/blob/master/doc/protocol.txt)

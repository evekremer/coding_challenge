# Coding challenge

## Contents

- [About Memcached](#about-memcached)
- [Installation](#installation)
- [Usage](#usage)
  - [Server](#server)
  - [Client demo](#client-demo)
  - [Tests](#tests)
- [Resources](#resources)

## About Memcached

Memcached is a high-performance, distributed memory object caching system, generic in nature, but originally intended for use in speeding up dynamic web applications by alleviating database load. You can think of it as a short-term memory for applications.

Memcached is made up of four main components. These components allow the client and the server to work together in order to deliver cached data as efficiently as possible:

- **Client software** - which is given a list of available Memcached servers
- **A client-based hashing algorithm** - chooses a server based on the “key”
- **Server software** - stores values and their keys into an internal hash table
- **LRU** - determines when to throw out old data or reuse memory

## Installation

Requires _Ruby v2.0.0_ and rake to be installed

## Usage

### Server

The server is started by invoking the following line from the terminal:

`ruby memcached/server.rb <socket_address> <socket_port>`

Optional _<socket_address>_ and _<socket_port>_ arguments determine the address where the server will be listening. `localhost:9999` is assigned by default.

### Client demo

'Client_demo.rb' provides a short demonstration of a client-server interaction, including sample commands sent and received with their corresponding actions, which is invoked by:

- `ruby memcached/client_demo.rb <socket_address> <socket_port>`

Additionally, 'Client.rb' allows to send requests to server and receive responses through the command line, which is invoked by:

- `ruby memcached/client.rb <socket_address> <socket_port>`

Optional _<socket_address>_ and _<socket_port>_ arguments determine the address for the TCP socket of the client. `localhost:9999` is assigned by default.

### Tests

In order to run tests, the server must be running and then invoke from the terminal using:
`rake`

which triggers all the unit tests defined under `/test/unit` folder to run.

## Resources

- Memcached wiki - https://github.com/memcached/memcached/wiki
- About Memcached - http://memcached.org/about
- Full list of commands - http://lzone.de/cheat-sheet/memcached
- The protocol specification - https://github.com/memcached/memcached/blob/master/doc/protocol.txt

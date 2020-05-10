# Coding challenge

## Contents

- [About Memcached](#about-memcached)
- [Installation and usage](#installation-and-usage)
  - [Server](#server)
  - [Client](#client)
  - [Tests](#tests)
- [Resources](#resources)

## About Memcached

Memcached is a high-performance, distributed memory object caching system, intended for use in speeding up dynamic web applications by alleviating database load, similar to a short-term memory for applications.

The system uses a client–server architecture. The servers maintain a key–value associative array; the clients populate this array and query it by key. When the table is full, subsequent inserts cause older data to be purged in least recently used (LRU) order.

Clients of memcached communicate with server through TCP connections. A given running memcached server listens on some (configurable) port; clients connect to that port, send commands to the server, read responses, and eventually close the connection. A subset of 2 types of Memcached commands are supported:

- **Storage commands** ("set", "add", "replace", "append", "prepend" and "cas") that ask the server to store some data identified by a key. The client sends a command line, and then a data block; after that the client expects one line of response, which will indicate success or failure. Some commands involve sending an expiration time relative to the item.

- **Retrieval commands** ("get", "gets") ask the server to retrieve data corresponding to a set of keys (one or more keys in one request). For each item the server finds, it sends information about the item and one data block with the item's data.

## Installation and Usage

Requires _Ruby v2.7.1p83_ to be installed (current stable release) although older versions may work.

### Server

The server is started by running:

`$ ruby ./lib/memcached.rb <socket_address> <socket_port>`

Optional _<socket_address>_ and _<socket_port>_ arguments determine the address where the server will be accepting client connections. `0.0.0.0:9999` is assigned by default.

### Client

'Client_demo.rb' provides a short demo of a client-server connection, including sample commands, which is invoked by:

- `$ ruby ./lib/memcached/client/client_demo.rb <socket_address> <socket_port>`

Additionally, 'Client.rb' allows to send requests to server and receive responses through the command line, invoked by:

- `$ ruby ./lib/memcached/client/client.rb <socket_address> <socket_port>`

Optional _<socket_address>_ and _<socket_port>_ arguments determine the address for the TCP socket of the client. `localhost:9999` is assigned by default.

### Tests

In order to run the tests, invoke:

- `$ ruby ./test/ts_unit_tests.rb`

which runs all the unit tests defined under `/test/unit` directory, excluding the server tests.

And with the server running, invoke:

- `$ ruby ./test/ts_server_unit_tests.rb`

which runs all the unit tests defined under `/test/unit/server` directory.

## Resources

- Memcached wiki - https://github.com/memcached/memcached/wiki
- About Memcached - http://memcached.org/about
- Full list of commands - http://lzone.de/cheat-sheet/memcached
- The protocol specification - https://github.com/memcached/memcached/blob/master/doc/protocol.txt

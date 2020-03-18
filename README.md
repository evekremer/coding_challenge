# Coding challenge

## Contents

* [Memcached](#memcached)
  * [How it works](#how-it-works)
  * [Design and architecture](#design-and-architecture)
* [Installation and usage](#installation-and-usage)
* [Tests](#tests)
* [Further resources](#further-resources)

## Memcached
### How it works



### Design and architecture

Memcached is made up of four main components. These components allow the client and the server to work together in order to deliver cached data as efficiently as possible:

* **Client software** - which is given a list of available Memcached servers
* **A client-based hashing algorithm** - chooses a server based on the “key”
* **Server software** - stores values and their keys into an internal hash table
* **LRU** - determines when to throw out old data or reuse memory

## Installation and usage

You need *Ruby v2.0.0* installed.

## Tests

## Further resources
*  [Memcached wiki](https://github.com/memcached/memcached/wiki)
*  [Full list of commands](http://lzone.de/cheat-sheet/memcached)
*  [The protocol specification](https://github.com/memcached/memcached/blob/master/doc/protocol.txt)

# Node.js service SysVinit scripts

These are some simple init.d scripts for a node server. They can be used on SysVinit systems like Debian Squeeze.


## Configuration

The scripts assume the following configuration (you might adjust the paths):

 * The scripts are installed in `/var/www/node.example.com`
 * The server script is server.js
 * The server runs as user www-data (i.e. no privileged ports)
 * The server listens on port `10080`, but is redirected from port `80` (via iptables)
 * Node is installed in `/opt/nodejs/v0.10`
 * All output is logged to `/var/log/node-service.log`


## TCP settings

Some TCP tweaks are done in the init script. This allows us to use many connections (open files) and reduce the timeouts, so e.g. broken WebSocket connections don't stay at the server for 2 hours.

```
    # To allow many connections
    ulimit -n 32767
    
    # TCP tweaks
    sysctl -q -w net.ipv4.tcp_retries2=5 # 15
    sysctl -q -w net.ipv4.tcp_keepalive_time=300 # 7200
    sysctl -q -w net.ipv4.tcp_keepalive_probes=2 # 9
    sysctl -q -w net.ipv4.tcp_keepalive_intvl=5 # 75
```

As we cannot listen on port 80 as non-root user, we have to redirect port 80 to 10080 (where the server listens):

```
    # Redirect privileged ports
    iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 10080
```

This can of course be commented out if redirection is done with a load balancer like nginx.


## Respawn on exit

The "node-service.sh" script restarts the node process when it crashes. The same can be achieved with [forever](https://github.com/indexzero/forever), but I did not find a good way to run forever from an init script.


#### Author: [Nico Kaiser][0]

[0]: http://siriux.net/

const i2pdconf = r"""
ipv4 = true
ipv6 = true

ssu = false

bandwidth = X
share = 1

# notransit = true
# floodfill = true

[ntcp2]
enabled = true

[ssu2]
enabled = true
published = true

[http]
enabled = true
address = 127.0.0.1
port = 7070
strictheaders = false
# auth = true
# user = i2pd
# pass = changeme

[httpproxy]
enabled = true
address = 127.0.0.1
port = 4444
inbound.length = 1
inbound.quantity = 5
outbound.length = 1
outbound.quantity = 5
signaturetype=7
i2cp.leaseSetType=3
i2cp.leaseSetEncType=0,4
keys = proxy-keys.dat
# addresshelper = true
# outproxy = http://false.i2p
## httpproxy section also accepts I2CP parameters, like "inbound.length" etc.

[socksproxy]
enabled = true
address = 127.0.0.1
port = 4447
keys = proxy-keys.dat
# outproxy.enabled = false
# outproxy = 127.0.0.1
# outproxyport = 9050
## socksproxy section also accepts I2CP parameters, like "inbound.length" etc.

[sam]
enabled = false
# address = 127.0.0.1
# port = 7656

[precomputation]
elgamal = false

[upnp]
enabled = false
# name = I2Pd

[reseed]
verify = true
## Path to local reseed data file (.su3) for manual reseeding
# file = /path/to/i2pseeds.su3
## or HTTPS URL to reseed from
# file = https://legit-website.com/i2pseeds.su3
## Path to local ZIP file or HTTPS URL to reseed from
# zipfile = /path/to/netDb.zip
## If you run i2pd behind a proxy server, set proxy server for reseeding here
## Should be http://address:port or socks://address:port
# proxy = http://127.0.0.1:8118
## Minimum number of known routers, below which i2pd triggers reseeding. 25 by default
# threshold = 25

[limits]
transittunnels = 50

[persist]
profiles = false
""";

const tunnelsconf = r"""[p3pch4t]
type = http
host = 127.0.0.1
port = 16424
inport = 80
keys = p3pch4t.dat""";

const supportedEvents = [
  "/core/selfpgp",
  "introduce.v1",
  "text.v1",
  "file.v1",
  "calendar.v1.sync.v1",
];

const ssmdcv1SupportedEvents = [
  "/core/selfpgp",
  "introduce.v1",
  "text.v1",
  "file.v1",
  "calendar.v1.sync.v1",
];

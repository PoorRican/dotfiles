# Local LAN hostname/domain discovery

Use this when the target is a device on the user's home/LAN network and the goal is to recover router-provided hostnames such as `host.home.local`.

## Pattern that worked

1. Identify the active subnet and router/DNS server:
   - `ip route`
   - `ip -brief addr`
   - `resolvectl status`
2. Ping/ARP sweep the LAN without DNS first, so name lookup cannot hang discovery:
   - `nmap -sn -n 192.168.1.0/24`
   - Then inspect `ip neigh show dev <iface>` for MAC addresses.
3. Query the router DNS directly for known guesses and PTRs. This bypasses local resolver policy and is useful when `.local` names are treated specially by mDNS/resolved.
   - A queries: `host.home.local`, `host`, likely prefixes.
   - PTR sweep: `<last-octet>.<third>.<second>.<first>.in-addr.arpa` for live IPs or the whole /24.
4. Verify candidate devices by forward+reverse consistency and reachability:
   - A record maps name -> IP.
   - PTR record maps IP -> FQDN.
   - `ping -c 2 -W 1 <ip>`.
   - Optional targeted `nmap -n -Pn -p <expected ports> <ip>`.
   - Optional MAC OUI lookup in `/usr/share/nmap/nmap-mac-prefixes` to corroborate vendor.

## Notes and pitfalls

- Prefer `nmap -sn -n` for the initial LAN host sweep. `-R`/reverse DNS can be slow or hang if DNS is incomplete; do reverse lookup separately after identifying live IPs.
- For `*.home.local` on systemd-resolved hosts, normal `getent`/`resolvectl query` may fail because `.local` is reserved/special for mDNS. Do not conclude the router lacks the record until you query the router DNS server directly.
- mDNS/DNS-SD can help (`avahi-browse -a -r -t`), but absence of an Avahi daemon/client result is not decisive for router-managed DHCP DNS names.
- When reporting results, include both FQDN and short name if both resolve, plus IP and a brief verification basis.

## Minimal direct-DNS Python probe

Use a small Python stdlib UDP DNS query when `dig`, `host`, or `nslookup` are missing. Query type 1 for A and type 12 for PTR against the router DNS IP discovered from `resolvectl status` or DHCP.
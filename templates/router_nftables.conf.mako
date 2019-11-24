#! /usr/local/sbin/nft -f

# flush ruleset
# icmpv6  = 58
# bgp     = 179
# ospfv3  = 89

<% bgp = 'bgp' in data.keys() %>

table inet filter {

	chain input {
		type filter hook input priority filter; policy drop;
		ct state established,related accept
    ct state invalid drop
    
    # accept all traffic on loopback
		iif "lo" accept

    # accepting ssh traffic from R0
    tcp dport 22 ip6 saddr fde4:4:f000:22::1 accept
    % for iface in data['ifaces']['routing']:
    <%
      dev = '%s-eth%s' % (data['name'], loop.index) 
      ip = 'fde4:4:f000::%s' % iface[1] 
    %>
	  iifname ${dev} ip6 nexthdr 89 counter accept
    % if bgp:
    iifname ${dev} tcp dport 179 counter accept
    % endif
    % endfor
    
		ip6 nexthdr 58 accept
	}

  chain forward {
    type filter hook forward priority 0; policy accept;
    % if bgp:
      % if 'e' in data['bgp']:
        % for iface in data['bgp']['e']['ifaces']:
    iifname ${iface} tcp dport 22 ip6 daddr fde4:4:f000::/63 counter drop
    iifname ${iface} icmpv6 type echo-request ip6 daddr fde4:4:f000::/63 counter drop
    iifname ${iface} ip6 nexthdr 89 counter drop
    iifname ${iface} tcp dport 179 counter drop
        % endfor
      % endif
    % endif
  }
  
  chain output {
    type filter hook output priority 0; policy accept;
  }

}


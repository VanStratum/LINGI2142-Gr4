#! /usr/local/sbin/nft -f

# flush ruleset

table inet filter {

	chain input {
		type filter hook input priority filter; policy drop;
		ct state established,related accept
    ct state invalid drop
    
    # accept all traffic on loopback
		iif "lo" accept

    # accepting ssh traffic from R0
    tcp dport 22 ip6 saddr fde4:4:f000:1::5 accept
    
    <% r = range(0, data['n_iface']) %>
    % for i in r:
      <%
        iface = '%s-eth%s' % (data['name'], i) 
        ip = 'fde4:4:f000:1::%s' % data['eth%s-subnet' % i] 
      %>
    # accept ospfv3
		iifname ${iface} ip6 daddr ${ip} ip6 nexthdr 89 counter accept
    % endfor
    
    # accept icmpv6
		ip6 nexthdr 58 accept
    
    # accept bgp
    tcp dport 179 accept
	}

  chain forward {
    type filter hook forward priority 0; policy accept;
  }
  
  chain output {
    type filter hook output priority 0; policy accept;
  }

}


iptables %(
  # Allow unlimited traffic on the loopback interface
  -A INPUT -i lo -j ACCEPT
  -A OUTPUT -o lo -j ACCEPT
  
  # Previously initiated and accepted exchanges bypass rule checking
  # Allow unlimited outbound traffic
  -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
  -A OUTPUT -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT  
)

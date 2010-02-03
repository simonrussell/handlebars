auth.user 'root'

# set the timezone to UTC
file.copy '/usr/share/zoneinfo/UTC', '/etc/localtime'

group "packages" do
  package %w(vim bzip2 hdparm less lynx wget dnsutils whois ssh-askpass iptables lvm2)
  gem %w(ohai json)
end

cook 'iptables'

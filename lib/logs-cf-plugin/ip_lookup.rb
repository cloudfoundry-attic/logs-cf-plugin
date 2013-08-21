require 'socket'

module IpLookup
  def self.best_ip_info
    ip = (my_first_public_ipv4 || my_first_private_ipv4)
    ip && ip.ip_address
  end

  private

  def self.my_first_private_ipv4
    Socket.ip_address_list.detect do |intf|
      intf.ipv4_private?
    end
  end

  def self.my_first_public_ipv4
    Socket.ip_address_list.detect do |intf|
      intf.ipv4? and
          !intf.ipv4_loopback? and
          !intf.ipv4_multicast? and
          !intf.ipv4_private?
    end
  end
end
{
  networking.nameservers = [ "127.0.0.1" ];
  services = {
    # mullvad DoT
    stubby = {
      enable = true;
      settings = {
        resolution_type = "GETDNS_RESOLUTION_STUB";
        dns_transport_list = [ "GETDNS_TRANSPORT_TLS" ];
        tls_authentication = "GETDNS_AUTHENTICATION_REQUIRED";
        listen_addresses = [ "127.0.0.1@5353" ];
        upstream_recursive_servers = [
          {
            address_data = "194.242.2.4";
            tls_auth_name = "base.dns.mullvad.net";
          }
        ];
      };
    };
  };
}


{ lib, config, pkgs, ... }: { 

    options = {
      mine.exit-node-routing.enable =
        lib.mkEnableOption "set systemwide wireguard tunnel, enable tailscale exit node routing thru it";
    };

    config = lib.mkIf config.mine.exit-node-routing.enable { 

      boot = {
        kernelModules = [ "iptables" "ip6tables" ];
        kernel.sysctl = {
          "net.ipv4.ip_forward" = true;
          "net.ipv6.conf.all.forwarding" = true;
        };
      };

      networking = {
        defaultGateway = {
          address = "192.168.6.1";
          interface = "eno1";
        };
        defaultGateway6 = {
          address = "fe80::ae1f:6bff:fe65:6849";
          interface = "eno1";
        };
        interfaces = {
      	  eno1 = {
  	   useDHCP = false;
   	   ipv4 = {
   	     addresses = [{
   	       address = "192.168.6.4";
   	       prefixLength = 24;
   	     }];
   	     routes = [
   	       {
   	         address = "192.168.6.0";
   	         prefixLength = 24;
   	         via = "192.168.6.1";
   	       }
   	       {
   	         address = "52.39.83.153";
   	         prefixLength = 32;
   	         via = "192.168.6.1";
   	       }
   	     ];
   	   };
   	   ipv6 = {
   	     addresses = [{
   	       address = "2601:602:9300:2::1238";
   	       prefixLength = 128;
   	     }];
   	     routes = [
   	       {
   	         address = "2600:1f14:2f74:aa8c:14a0:1ba7:b9b9:5847";
   	         prefixLength = 128;
   	         via = "fe80::ae1f:6bff:fe65:6849";
   	       }
   	     ];
   	   };
   	 };
	tailscale0 = {
          ipv4.routes = [
            {
              address = "100.64.0.0";
              prefixLength = 10;
            }
          ];
          ipv6.routes = [
            {
              address = "fd7a:115c:a1e0::";
              prefixLength = 48;
            }
          ];
	};
      };
      wg-quick.interfaces = {
        wg0 = {
          address = [ "10.69.81.138/32,fc00:bbbb:bbbb:bb01::6:5189/128" ]; # Internal Mullvad IP for the client
	  # dns = [ "194.242.2.4" ];
          listenPort = 51820;
          privateKeyFile = "/home/r6t/mullvad.key";
          peers = [
            {
              publicKey = "4ke8ZSsroiI6Sp23OBbMAU6yQmdF3xU2N8CyzQXE/Qw="; # Mullvad server's public key
              allowedIPs = [
                 "0.0.0.0/0,::0/0"
               ];
              endpoint = "138.199.43.65:51820"; # Mullvad server's endpoint
              persistentKeepalive = 25; # Ensure connection stays alive
            }
          ];
        };
      };
    };
  };
}

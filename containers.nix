{ config, pkgs, ... }:
{

  containers.ipfsgw = {
    localAddress = "10.0.10.2/24";
    privateNetwork = true;
    hostBridge = "br0";

    bindMounts = {
      "/var/lib/ipfs" = { hostPath = "/stor/ipfsgw/var/lib/ipfs"; isReadOnly = false; };
    };
    config = let
      wl_path = ''/var/lib/ipfs/whitelist.conf'';
    in
    {
      networking.defaultGateway = "10.0.10.1";
      networking.firewall.allowedTCPPorts = [ 80 5001 ];
      services.ipfs.enable = true;
      services.nginx = {
        enable = true;
        virtualHosts = {
          "_" = {
            default = true;
            extraConfig = ''
              include ${wl_path};
            '';
            locations."@ipfs" = {
              extraConfig = ''
                proxy_pass http://127.0.0.1:8080;
              '';
            };
          };
        };
      };
      systemd.services.nginx_reloader = {
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.systemd}/bin/systemctl reload nginx";
        };
      };
      systemd.paths.nginx_reloader = {
        wantedBy = [ "multi-user.target" ];
        requires = [ "ipfs.service" ];
        pathConfig = { PathChanged = "${wl_path}"; };
      };

    };
  };
}

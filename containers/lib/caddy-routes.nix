# Caddy reverse proxy route declarations for all incus containers.
# Single source of truth — consumed by host configs to generate caddy virtualHosts,
# and by containers to configure their own caddy when running in container mode (e.g. spire).
#
# Each key is a container name. The value is an attrset of domain -> route config.
# Route config: { upstream, compress (default true), extraConfig (default "") }
#
# To add routes for a new container, add an entry here and the host caddy config
# will pick it up automatically on next rebuild.
{
  audiobookshelf = {
    "audiobookshelf.r6t.io" = { upstream = "http://localhost:13378"; };
  };

  changedetection = {
    "changed.r6t.io" = { upstream = "http://localhost:5000"; };
  };

  dawarich = {
    "geo.r6t.io" = { upstream = "http://localhost:3033"; };
  };

  gitea = {
    "git.r6t.io" = { upstream = "http://localhost:3000"; };
  };

  immich = {
    "photos.r6t.io" = { upstream = "http://localhost:2283"; compress = false; };
  };

  it-tools = {
    "tools.r6t.io" = { upstream = "http://localhost:8040"; };
  };

  hermes = {
    "api.hermes.r6t.io" = { upstream = "http://localhost:8642"; compress = false; };
    "hermes.r6t.io" = { upstream = "http://localhost:9119"; };
  };

  jellyfin = {
    "jellyfin.r6t.io" = { upstream = "http://localhost:8096"; };
  };

  llm = {
    "llm.r6t.io" = { upstream = "http://localhost:8088"; };
    "oi.r6t.io" = { upstream = "http://localhost:8087"; };
  };

  miniflux = {
    "miniflux.r6t.io" = { upstream = "http://localhost:8080"; };
  };

  ntfy = {
    "mollysocket.r6t.io" = { upstream = "http://localhost:8020"; };
    "ntfy.r6t.io" = { upstream = "http://localhost:8083"; };
  };

  searxng = {
    "searxng.r6t.io" = { upstream = "http://localhost:8085"; };
  };

  # Spire runs services locally — use 127.0.0.1 explicitly because
  # Loki/Grafana bind to IPv4 only and localhost may resolve to ::1
  spire = {
    "grafana.r6t.io" = { upstream = "http://127.0.0.1:3099"; };
    "loki.r6t.io" = { upstream = "http://127.0.0.1:3030"; };
    "pid.r6t.io" = { upstream = "http://127.0.0.1:1411"; };
    "prometheus.r6t.io" = { upstream = "http://127.0.0.1:9001"; };
  };

  ladder = {
    "ladder.r6t.io" = { upstream = "http://localhost:8082"; };
  };

  stirlingpdf = {
    "spdf.r6t.io" = { upstream = "http://localhost:89"; };
  };

  # Docker-based containers (no containers/*.nix — use the docker image)
  paperless = {
    "paperless.r6t.io" = { upstream = "http://localhost:8000"; };
  };

  pinchflat = {
    "pinchflat.r6t.io" = {
      upstream = "http://localhost:8945";
      extraConfig = ''
        @outside {
          not {
            remote_ip 127.0.0.0/8 ::1 100.64.0.0/10 fd7a:115c:a1e0::/48
          }
        }
        respond @outside 403
      '';
    };
  };

  pirate-ship = {
    "radarr.r6t.io" = { upstream = "http://localhost:7878"; };
    "sab.r6t.io" = { upstream = "http://localhost:8081"; };
    "sonarr.r6t.io" = { upstream = "http://localhost:8989"; };
    "tx.r6t.io" = { upstream = "http://localhost:9091"; };
  };

  sts = {
    "sts.r6t.io" = { upstream = "http://localhost:47811"; };
    "stsb.r6t.io" = { upstream = "http://localhost:47812"; };
  };
}

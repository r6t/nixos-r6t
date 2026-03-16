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

  immich = {
    "photos.r6t.io" = { upstream = "http://localhost:2283"; compress = false; };
  };

  jellyfin = {
    "jellyfin.r6t.io" = { upstream = "http://localhost:8096"; };
  };

  llm = {
    "any.r6t.io" = { upstream = "http://localhost:3001"; };
    "oi.r6t.io" = { upstream = "http://localhost:8087"; };
    "ollama.r6t.io" = { upstream = "http://localhost:11434"; };
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

  # Docker-based containers (no containers/*.nix — use the docker image)
  it-tools = {
    "tools.r6t.io" = { upstream = "http://localhost:8040"; };
  };

  ladder = {
    "ladder.r6t.io" = { upstream = "http://localhost:8082"; };
  };

  paperless = {
    "paperless.r6t.io" = { upstream = "http://localhost:8000"; };
  };

  pirate-ship = {
    "radarr.r6t.io" = { upstream = "http://localhost:7878"; };
    "sab.r6t.io" = { upstream = "http://localhost:8081"; };
    "sonarr.r6t.io" = { upstream = "http://localhost:8989"; };
    "tx.r6t.io" = { upstream = "http://localhost:9091"; };
  };

  pocket-id = {
    "pid.r6t.io" = { upstream = "http://localhost:1411"; };
    "auth.r6t.io" = { upstream = "http://localhost:1411"; };
  };

  sts = {
    "sts.r6t.io" = { upstream = "http://localhost:47811"; };
    "stsb.r6t.io" = { upstream = "http://localhost:47812"; };
  };
}

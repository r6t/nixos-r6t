{ lib, pkgs }:

let
  caddyVersion = "v2.9.1";
  route53Version = "v1.5.1";
in
pkgs.stdenv.mkDerivation rec {
  pname = "caddy-with-route53";
  version = caddyVersion;
  name = "${pname}-${version}";

  src = pkgs.fetchFromGitHub {
    owner = "caddyserver";
    repo = "caddy";
    rev = caddyVersion;
    sha256 = "sha256-hzDd2BNTZzjwqhc/STbSAHnNlP7g1cFuMehqU1LumQE=";
  };

  nativeBuildInputs = [ pkgs.go pkgs.git pkgs.xcaddy ];

  buildPhase = ''
    export HOME=$TMPDIR
    export GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    mkdir -p $out/bin
    xcaddy build ${caddyVersion} \
      --with github.com/caddy-dns/route53@${route53Version} \
      --output $out/bin/caddy
  '';

  installPhase = "true";

  meta = with lib; {
    description = "Caddy with Route53 DNS plugin";
    homepage = "https://caddyserver.com";
    license = licenses.asl20;
    mainProgram = "caddy";
    maintainers = [ ];
  };
}


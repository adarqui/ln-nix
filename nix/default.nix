with import <nixpkgs> {};

let dependencies = rec {
  _erlang = erlang.override { wxSupport = false; };
  _rabbitmq_server = rabbitmq_server.override { erlang = _erlang; };
  _enabled_plugins = builtins.toFile "enabled_plugins" "[rabbitmq_management].";
};
in with dependencies;

stdenv.mkDerivation rec {
  name = "env";

  # Mandatory boilerplate for buildable env
  env = buildEnv { name = name; paths = buildInputs; };
  builder = builtins.toFile "builder.sh" ''
    source $stdenv/setup; ln -s $env $out
  '';

  # Customizable development requirements
  buildInputs = [
    # Add packages from nix-env -qaP | grep -i needle queries
    redis
    postgresql94
    _rabbitmq_server
  ];

  # Customizable development shell setup with at last SSL certs set
  shellHook = ''
    mkdir -p $PWD/var
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
    export RABBITMQ_LOG_BASE=$PWD/var
    export RABBITMQ_ENABLED_PLUGINS_FILE=${_enabled_plugins}
  '';
}

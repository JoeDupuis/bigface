{ pkgs, lib, config, inputs, ... }:{

  cachix.enable = false;

  env = {
    LD_LIBRARY_PATH = "${config.devenv.profile}/lib";
  };

  packages = with pkgs; [
    git
    libyaml
    sqlite-interactive
    bashInteractive
    openssl
    curl
    libxml2
    libxslt
    libffi
    docker
    nodejs_22
    temurin-bin-21
  ];

  enterShell = ''
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
  '';

  languages.ruby.enable = true;
  languages.ruby.versionFile = ./.ruby-version;
}

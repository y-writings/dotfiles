{ pkgs, systemConfig }:
let
  brewfile = pkgs.writeText "Brewfile" systemConfig.homebrew.brewfile;
in
pkgs.runCommand "dbeaver-vrapper-check"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.ruby
      pkgs.shellcheck
    ];
  }
  ''
    ruby -c ${brewfile}
    ruby -rjson -rshellwords - ${brewfile} > postinstall.json <<'RUBY'
    def cask(name, **options)
      puts JSON.generate(Shellwords.split(options.fetch(:postinstall)))
    end
    line = File.readlines(ARGV.fetch(0)).find { |entry| entry.start_with?('cask "dbeaver-community",') }
    abort 'DBeaver cask is missing from Brewfile' unless line
    eval(line)
    RUBY

    python3 ${./dbeaver-vrapper.py} postinstall.json
    touch "$out"
  ''

{ ... }:

let
  system = (system: (import ./default.nix { inherit system; }));
  linux = system "x86_64-linux";
  darwin = system "x86_64-darwin";

  ethereum-test-suite = x: x.fetchFromGitHub {
    owner = "ethereum";
    repo = "tests";
    rev = "2750addccdac71f6beb139170171488592fea917";
    sha256 = "1xdqx0ggr99569g8jcsqzllgp6wpgyc2v19x8wg8racywc61x0p4";
  };

  # run all General State Tests, skipping tests that deal with "anomalies on the main network"
  # (see section K.1 of https://ethereum.github.io/yellowpaper/paper.pdf), and some performance
  # heavy ones.
  hevmCompliance = x: x.runCommand "hevm-compliance" {} ''
    mkdir "$out"
    export PATH=${x.pkgs.hevm}/bin:${x.pkgs.jq}/bin:$PATH
    ${x.pkgs.hevm}/bin/hevm compliance \
      --tests ${ethereum-test-suite x} \
      --skip "(RevertPrecompiledTouch_storage_d0g0v0|RevertPrecompiledTouch_storage_d3g0v0|Create1000Byzantium_d0g1v0)" \
      --timeout 20 \
      --html > $out/index.html
    ${x.pkgs.hevm}/bin/hevm compliance \
      --tests ${ethereum-test-suite x} \
      --group "VM"
  '';

  # These packages should always work and be available in the binary cache.
  stable = dist: with dist.pkgs; {
    inherit dai;
    inherit dapp-which;
    inherit dapp;
    inherit ethsign;
    inherit evmdis;
    inherit go-ethereum-unlimited;
    inherit go-ethereum;
    inherit hevm;
    inherit qrtx-term;
    inherit qrtx;
    inherit seth;
    inherit setzer;
    inherit token;

    hevm-compliance = hevmCompliance dist;
  # the union is necessary because nix-build does not evaluate sets
  # recursively, and `solc-versions` is a set
  } // dist.pkgs.solc-versions ;

in {
  dapphub.linux.stable = stable linux;
  dapphub.darwin.stable = stable darwin;
}

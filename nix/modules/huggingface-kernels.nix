# Hugging Face kernels CLI tools from the upstream flake
{ pkgs, inputs, ... }:
let
  kernelsPackages = inputs.huggingface-kernels.packages.${pkgs.system};
in {
  home.packages = [
    kernelsPackages.kernels
    kernelsPackages.kernel-builder
  ];
}

# Catalog-pinned Hindsight plugin and supplemental packages for the sealed Hermes runtime.
# Existing Hermes dependencies are supplied by its venv; propagating another
# aiohttp/pydantic closure would shadow core packages and fail the collision gate.
{ pkgs, python }:
let
  revision = "d56c4acdf59c41957613d399094cdf8c489b060c";
  sourceHashes = {
    "__init__.py" = "sha256-PZt+XKVegGaYiniCj4aAY3eK8y1o17ncXTobfTsBB8E=";
    "embedded.py" = "sha256-nCl0K8h0jLRbTvdy08PC9lUPhAExL3+lYVKpew9Nm70=";
    "settings.py" = "sha256-3Y2BUuHDPN1EJdyrOEIhZAafafJypH9nmRPE46yzTTM=";
    "config_schema.py" = "sha256-TJA5ijz/rZqyFW38gYq/Iu+qYkreGOzKz3RU2MUhtxU=";
    "setup.py" = "sha256-pZLi5eMbWY4w+suWMRNWB163RpiAtSX2REtyDrFEFQE=";
    "templates.py" = "sha256-6sBe9kG1yPqWELm5WfMtuPNA4UI9U2PryItgHLhLYA4=";
    "pyproject.toml" = "sha256-rZt1HOITVyZLsfXKKi5fAmCZxfvY9ySRuXyAu+aEYos=";
    "plugin.yaml" = "sha256-eIKZWRmB6yNTvU7EKfPEEO+traAEESGrj4OtbSAgENo=";
  };
  wheel = pname: version: url: hash: python.pkgs.buildPythonPackage {
    inherit pname version;
    format = "wheel";
    src = pkgs.fetchurl { inherit url hash; };
    # These packages augment, rather than duplicate, Hermes' sealed closure.
    # Validate their real requirements/imports against the final wrapped runtime.
    dontCheckRuntimeDeps = true;
    doCheck = false;
  };
in {
  # This main-branch pin follows v2026.9.24 (pyproject version 0.21.5)
  # by 8107 commits. GitHub compare confirmed base == merge-base and
  # behind_by == 0. Nix's default 0.0.0 stamp otherwise rejects plugins.
  # Recompute this identity when changing the Hermes input, never fake the
  # minimum or remove requires_hermes from the upstream plugin manifest.
  hermesIdentity = {
    revision = "aa30e02d860fb2683db0d9d2241d4980a6ee6978";
    version = "0.21.5";
    distance = 8107;
  };
  pythonPackages = [
    (wheel "aiohttp-retry" "2.9.1"
      "https://files.pythonhosted.org/packages/1a/99/84ba7273339d0f3dfa57901b846489d2e5c2cd731470167757f1935fffbd/aiohttp_retry-2.9.1-py3-none-any.whl"
      "sha256-ZtJ1nRkhg4JWoFo/gK1+ckk28IPjW+WrteFu7Wvm3FQ=")
    (wheel "hindsight-client" "0.10.3"
      "https://files.pythonhosted.org/packages/54/31/5157bd9f73dca7ef2516470ff85818e03d6167f031cfcc96ff1c263ebc12/hindsight_client-0.10.3-py3-none-any.whl"
      "sha256-tNDRu8KdzU7yWkojoIpIBG1TN7cEva+rsC0AENKZoGg=")
    (wheel "hindsight-embed" "0.10.3"
      "https://files.pythonhosted.org/packages/f3/c4/4854a2e245937026dcdf3291506dc51b16dc9dcb9e673c8f6c4668d76632/hindsight_embed-0.10.3-py3-none-any.whl"
      "sha256-KQuB2DY+mW8Wb1M9MsYec0r10QRpWiUrDg9ynPNuzPE=")
  ];
  # HTTP stays on each host's loopback; the LAN hop is authenticated SSH.
  tunnelService = {
    Unit.Description = "Encrypted Hindsight connection (k-research-agent)";
    Service = {
      Type = "exec";
      ExecStart = "${pkgs.openssh}/bin/ssh -N -T -o BatchMode=yes -o StrictHostKeyChecking=yes -o ExitOnForwardFailure=yes -o ConnectTimeout=10 -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -L 127.0.0.1:18888:127.0.0.1:30520 wst";
      Restart = "always";
      RestartSec = 5;
      UMask = "0077";
    };
    Install.WantedBy = [ "default.target" ];
  };
  files = pkgs.lib.mapAttrs' (name: hash:
    let
      source = pkgs.fetchurl {
        name = "hindsight-${name}";
        url = "https://raw.githubusercontent.com/vectorize-io/hindsight/${revision}/hindsight-integrations/hermes/${name}";
        inherit hash;
      };
    in pkgs.lib.nameValuePair "plugins/hindsight/${name}" (
      if name == "plugin.yaml" then pkgs.writeText "hindsight-plugin-external.yaml" ''
        ${builtins.readFile source}
        # Nix supplies the Python closure; Hermes PM must not sync this plugin.
        python_runtime: external
      '' else source
    )) sourceHashes // {
    "hindsight/config.json" = builtins.toJSON {
      mode = "local_external";
      api_url = "http://127.0.0.1:18888";
      bank_id = "kairos-hindsight";
      memory_mode = "hybrid";
      auto_recall = true;
      auto_retain = true;
      recall_sync = true;
      # Keep newly retained raw facts visible while observations consolidate.
      recall_types = [ "observation" "world" "experience" ];
      recall_budget = "mid";
    };
  };
}

{ ... }:

{
  imports = [
    ../modules/home-manager/obsidian-sync.nix
  ];

  my.obsidian-sync = {
    enable = true;
    vaults = [
      {
        name = "kairos";
        path = "/home/swe/wikis/kairos";
      }
      {
        name = "memex";
        path = "/home/swe/wikis/memex";
      }
    ];
  };
}

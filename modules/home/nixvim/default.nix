{ lib, config, inputs, pkgs, ... }: { 

    options = {
      mine.home.nixvim.enable =
        lib.mkEnableOption "enable nixvim in home-manager";
    };

    config = lib.mkIf config.mine.home.nixvim.enable { 
      home-manager.users.r6t.programs.nixvim = {
        enable = true;
        extraPlugins = [ pkgs.vimPlugins.rose-pine ];
        colorschemes.rose-pine.enable = true;
 #       defaultEditor = true;
 #       viAlias = true;
 #       vimAlias = true;
 #       vimdiffAlias = true;
 #       plugins = with pkgs.vimPlugins; [
 #         rose-pine
 #       ];
 #       extraConfig = ''
 #         colorscheme rose-pine
 #         set number relativenumber
 #         set nowrap
 #         set nobackup
 #         set nowritebackup
 #         set noswapfile
 #       '';
 #       # extraLuaConfig goes to .config/nvim/init.lua, which cannot be managed as an individual file when using this
 #       extraLuaConfig = ''
 #       '';
 #       extraPackages = [
 #       ];
      };
    };
}
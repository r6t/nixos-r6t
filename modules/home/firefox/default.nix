{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.firefox.enable =
        lib.mkEnableOption "enable firefox in home-manager";
    };

    config = lib.mkIf config.mine.home.firefox.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ firefox-wayland ];

      home-manager.users.r6t.programs.firefox = {
        enable = true;
        package = pkgs.firefox-wayland;
        ###
        profiles."default" = {
          id = 0;
          settings = {
            "identity.sync.enabled" = true;
            "identity.sync.username" = "$(cat ${config.sops.secrets."firefox_sync".path})";
            "identity.sync.engine.addons" = true;
            "identity.sync.engine.prefs" = true;
            "identity.sync.engine.tabs" = true;
            "identity.sync.engine.extensions" = true;
            "identity.sync.engine.forms" = true;
            "identity.sync.engine.history" = true;
            "identity.sync.engine.passwords" = true;
            "identity.sync.engine.addresses" = true;
            "identity.sync.engine.creditcards" = true;
            "identity.sync.engine.payments" = true;
            
            # General Settings
            "general.smoothScroll" = true;
            "browser.download.folderList" = 2;
            "browser.download.dir" = "$HOME/Downloads";
            "browser.startup.homepage" = "";
            
            # Privacy & Security Settings
            "privacy.donottrackheader.enabled" = true;
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.cryptomining.enabled" = false;
            "privacy.trackingprotection.socialmedia.enabled" = false;
            
            # Cookie Settings
            "network.cookie.cookieBehavior" = 4; # Block cross-site tracking cookies
            "network.cookie.lifetimePolicy" = 2; # Session cookies only (delete on close)
            
            # Strict Privacy Mode
            "privacy.restrict3rdpartycookies" = true; # Restrict third-party cookies
            "privacy.cpd.enabled" = true; # Enable Content Preference for DOM storage
            "privacy.cpd.excludedDomains" = ""; # Add domains you want to exclude from strict mode if needed
            
            # Clear Data On Close Settings
            "privacy.clearOnShutdown.cookies" = true;
            "privacy.clearOnShutdown.cache" = true;
            "privacy.clearOnShutdown.history" = true;
            "privacy.clearOnShutdown.formData" = true;
            
            # Performance Settings
            "browser.preferences.defaultPerformanceSettings.enabled" = false; # Do not use recommended performance settings
            "layers.acceleration.disabled" = true; # Disable hardware acceleration

            # List of sites where cookies should be allowed to persist across sessions
            "network.cookie.cookiePrefetch" = 0; # Disable cookie prefetching
            "extensions.noNewNetPrefsMigrate" = true; # Prevent migration of new network preferences from extensions
          };
      };
      };
    };
}
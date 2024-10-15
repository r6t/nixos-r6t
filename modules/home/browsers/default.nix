{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.browsers.enable =
        lib.mkEnableOption "enable desktop web browsers in home-manager";
    };

    config = lib.mkIf config.mine.home.firefox.enable { 
    
      home-manager.users.r6t.home.packages = with pkgs; [ 
        brave
        librewolf
        ungoogled-chromium
      ];

      home-manager.users.r6t.programs.firefox = {
        enable = true;
        profiles."default" = {
          id = 0;
          settings = {
            "app.shield.optoutstudies.enabled" = false;
            "browser.crashReports.enabled" = false;
            "browser.discovery.enabled" = false;
            "browser.download.dir" = "$HOME/Downloads";
            "browser.download.folderList" = 2;
            "browser.newtab.url" = "about:blank";
            "browser.newtabpage.enabled" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
            "browser.newtabpage.activity-stream.feeds.discoverystreamfeed" = false;
            "browser.preferences.defaultPerformanceSettings.enabled" = false; # Do not use recommended performance settings
            "browser.search.defaultenginename" = "DuckDuckGo";
            "browser.search.suggest.enabled" = false; # Disable search suggestions
            "browser.urlbar.suggest.searches" = false; # Additional setting to disable search suggestions in the address bar.
            "browser.search.showOneOffButtons" = false; # Possibly relevant for disabling quick-search buttons for other search engines.
            "browser.newtabpage.activity-stream.showSponsored" = false; # Disable sponsored content on new tab page
            "browser.startup.homepage" = "about:blank";
            "browser.startup.page" = 0; # about:blank in new windows
            "browser.urlbar.placeholderName" = "DuckDuckGo";
            "browser.urlbar.placeholderName.private" = "DuckDuckGo";
            "datareporting.healthreport.uploadEnabled" = false;
            "dom.security.https_only_mode" = true; # Enable HTTPS-Only Mode
            "extensions.getAddons.showPane" = false;
            "extensions.noNewNetPrefsMigrate" = true; # Prevent migration of new network preferences from extensions
            "general.smoothScroll" = true;
            "identity.sync.enabled" = true;
            "identity.sync.engine.addons" = true;
            "identity.sync.engine.addresses" = true;
            "identity.sync.engine.creditcards" = true;
            "identity.sync.engine.extensions" = true;
            "identity.sync.engine.forms" = true;
            "identity.sync.engine.history" = true;
            "identity.sync.engine.passwords" = true;
            "identity.sync.engine.payments" = true;
            "identity.sync.engine.prefs" = true;
            "identity.sync.engine.tabs" = true;
            "identity.sync.username" = "$(cat ${config.sops.secrets."firefox_sync".path})";
            "layers.acceleration.disabled" = true; # Disable hardware acceleration
            "network.cookie.cookieBehavior" = 1; # Block all cross-site cookies
            "network.cookie.cookiePrefetch" = 0; # Disable cookie prefetching
            "network.cookie.lifetimePolicy" = 2; # Session cookies only (delete on close)
            "privacy.clearOnShutdown.cache" = true;
            "privacy.clearOnShutdown.cookies" = true;
            "privacy.clearOnShutdown.formData" = false;
            "privacy.clearOnShutdown.history" = false;
            "privacy.cpd.enabled" = true; # Enable Content Preference for DOM storage
            "privacy.cpd.excludedDomains" = ""; # Add domains you want to exclude from strict mode if needed
            "privacy.donottrackheader.enabled" = true;
            "privacy.restrict3rdpartycookies" = true; # Restrict third-party cookies
            "privacy.trackingprotection.cryptomining.enabled" = false;
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.socialmedia.enabled" = false;
            "signon.rememberSignons" = false; # Disable Firefox credential store
            "toolkit.telemetry.enabled" = false;
            "ui.systemUsesDarkTheme" = 1;
          };
      };
      };
    };
}

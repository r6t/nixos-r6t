{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.browsers.enable =
      lib.mkEnableOption "enable desktop web browsers in home-manager";
  };

  config = lib.mkIf config.mine.home.browsers.enable {

    home-manager.users.${userConfig.username} = {
      home.packages = with pkgs; [
        brave
        librewolf
        ungoogled-chromium
      ];
      programs.firefox = {
        enable = true;
        profiles."default" = {
          id = 0;
          search = {
            default = "Searxng";
            force = true;
            engines = {
              "Searxng" = {
                urls = [{
                  template = "https://searxng.r6t.io/search";
                  params = [
                    { name = "q"; value = "{searchTerms}"; }
                  ];
                }];
                icon = "https://searxng.r6t.io/favicon.ico";
                updateInterval = 24 * 60 * 60 * 1000; # Daily
                definedAliases = [ "@sx" ];
              };
              "ddg".metaData.hidden = false;
              "google".metaData.hidden = true;
              "amazondotcom-us".metaData.hidden = true;
              "bing".metaData.hidden = true;
              "ebay".metaData.hidden = true;
            };
          };
          settings = {
            # App settings
            app = {
              shield.optoutstudies.enabled = false;
              normandy = {
                api_url = "";
                enabled = false;
              };
            };

            # Browser settings
            browser = {
              crashReports.enabled = false;
              discovery.enabled = false;
              download = {
                dir = "$HOME/Downloads";
                folderList = 2;
              };
              newtab.url = "https://uptime.r6t.io/status/core";
              newtabpage = {
                enabled = false;
                activity-stream = {
                  showSponsoredTopSites = false;
                  feeds.section.topstories = false;
                  feeds.discoverystreamfeed = false;
                  showSponsored = false;
                };
              };
              preferences.defaultPerformanceSettings.enabled = false;
              search = {
                defaultenginename = "Searxng";
                suggest.enabled = false;
                showOneOffButtons = false;
              };
              startup = {
                homepage = "https://uptime.r6t.io/status/core";
                page = 0;
              };
              urlbar = {
                placeholderName = "Searxng";
                suggest = {
                  searches = false;
                  history = false;
                  bookmark = false;
                  openpage = false;
                  topsites = false;
                };
              };
              formfill.enable = false;
              ping-centre.telemetry = false;
              tabs.crashReporting.sendReport = false;
            };

            # Data reporting settings
            datareporting = {
              healthreport.uploadEnabled = false;
              policy.dataSubmissionEnabled = false;
            };

            # DOM settings
            dom.security.https_only_mode = true;

            # Extensions settings
            extensions = {
              getAddons.showPane = false;
              noNewNetPrefsMigrate = true;
              pocket.enabled = false;
              formautofill = {
                addresses.enabled = false;
                creditCards.enabled = false;
              };
            };

            # General settings
            general.smoothScroll = true;

            # Identity settings
            identity.sync = {
              enabled = true;
              username = "$(cat /run/secrets/firefox_sync)";
              engine = {
                addons = true;
                addresses = true;
                creditcards = true;
                extensions = true;
                forms = true;
                history = true;
                passwords = true;
                payments = true;
                prefs = true;
                tabs = true;
              };
            };

            # Layers settings
            layers.acceleration.disabled = true;

            # Media settings
            media.peerconnection.enabled = false;

            # Network settings
            network = {
              cookie = {
                cookieBehavior = 1;
                cookiePrefetch = 0;
                lifetimePolicy = 2;
              };
              dns.disablePrefetch = true;
              prefetch-next = false;
              predictor = {
                enabled = false;
                enable-prefetch = false;
              };
            };

            # Privacy settings
            privacy = {
              clearOnShutdown = {
                cache = true;
                cookies = true;
                formData = false;
                history = false;
              };
              cpd = {
                enabled = true;
                excludedDomains = "";
              };
              donottrackheader.enabled = true;
              restrict3rdpartycookies = true;
              trackingprotection = {
                cryptomining.enabled = true;
                enabled = true;
                socialmedia.enabled = true;
                fingerprinting.enabled = true;
              };
              firstparty.isolate = true;
              resistFingerprinting = true;
              partition.network_state = true;
            };

            # Sign-on settings
            signon.rememberSignons = false;

            # Toolkit settings
            toolkit.telemetry = {
              enabled = false;
              archive.enabled = false;
              bhrPing.enabled = false;
              firstShutdownPing.enabled = false;
              newProfilePing.enabled = false;
              reportingpolicy.firstRun = false;
              shutdownPingSender.enabled = false;
              unified = false;
              updatePing.enabled = false;
            };

            # UI settings
            ui.systemUsesDarkTheme = 1;

            # Geo settings
            geo.enabled = false;

            # Breakpad settings
            breakpad.reportURL = "";
          };
        };
      };
    };
  };
}


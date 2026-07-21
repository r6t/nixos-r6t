{
  services.flatpak = {
    packages = [
      { appId = "org.libreoffice.LibreOffice"; origin = "flathub"; }
    ];

    overrides."org.libreoffice.LibreOffice" = {
      Context.sockets = [
        "x11"
        "!wayland"
      ];
      Environment.SAL_USE_VCLPLUGIN = "gen";
    };
  };
}

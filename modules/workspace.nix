# General workspace behavior settings:
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.plasma;
  inherit (import ../lib/wallpapers.nix { inherit lib; }) wallpaperPictureOfTheDayType wallpaperSlideShowType;
  inherit (import ./widgets/lib.nix { inherit lib; }) stringIfNotNull;

  cursorType = with lib.types; submodule {
    options = {
      theme = lib.mkOption {
        type = nullOr str;
        default = null;
        example = "Breeze_Snow";
        description = "The Plasma cursortheme. Run plasma-apply-cursortheme --list-themes for valid options.";
      };
      size = lib.mkOption {
        type = nullOr ints.positive;
        default = null;
        example = 24;
        description = "The size of the cursor. See the settings GUI for allowed sizes for each cursortheme.";
      };
    };
  };

  desktopIconSortingModeId = {
    manual = -1;
    name = 0;
    size = 1;
    date = 2;
    type = 6;
  };

  mouseActions = {
    applicationLauncher = "org.kde.applauncher";
    contextMenu = "org.kde.contextmenu";
    paste = "org.kde.paste";
    switchActivity = "switchactivity";
    switchVirtualDesktop = "org.kde.switchdesktop";
    switchWindow = "switchwindow";
  };

  mouseActionNamesEnum = lib.types.enum (builtins.attrNames mouseActions);

  anyThemeSet = (cfg.workspace.theme != null ||
    cfg.workspace.colorScheme != null ||
    (cfg.workspace.cursor != null && cfg.workspace.cursor.theme != null) ||
    cfg.workspace.lookAndFeel != null ||
    cfg.workspace.iconTheme != null);

  # Becomes true if any option under "cfg.workspace.desktop.icons" is set to something other than null.
  anyDesktopFolderSettingsSet =
    let
      recurse = l: lib.any (v: if builtins.isAttrs v then recurse v else v != null) (builtins.attrValues l);
    in
    recurse cfg.workspace.desktop.icons;

  # Becomes true if any option under "cfg.workspace.desktop.mouseActions" is set to something other than null.
  anyDesktopMouseActionsSet = lib.any (v: v != null) (builtins.attrValues cfg.workspace.desktop.mouseActions);

  splashScreenEngineDetect = theme: (if (theme == "None") then "none" else "KSplashQML");
in
{
  imports = [
    (lib.mkRenamedOptionModule [ "programs" "plasma" "workspace" "cursorTheme" ] [ "programs" "plasma" "workspace" "cursor" "theme" ])
  ];

  options.programs.plasma.workspace = {
    clickItemTo = lib.mkOption {
      type = with lib.types; nullOr (enum [ "open" "select" ]);
      default = null;
      description = ''
        Clicking files or folders should open or select them.
      '';
    };

    tooltipDelay = lib.mkOption {
      type = with lib.types; nullOr ints.positive;
      default = null;
      example = 5;
      description = ''
        The delay in milliseconds before an element's tooltip is shown when hovered over.
      '';
    };

    theme = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "breeze-dark";
      description = ''
        The Plasma theme. Run plasma-apply-desktoptheme --list-themes for valid options.
      '';
    };

    colorScheme = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "BreezeDark";
      description = ''
        The Plasma colorscheme. Run plasma-apply-colorscheme --list-schemes for valid options.
      '';
    };

    cursor = lib.mkOption {
      type = lib.types.nullOr cursorType;
      default = null;
      example = { theme = "Breeze_Snow"; size = 24; };
      description = ''
        Allows to configure the cursor in plasma. Both the theme and size are configurable.
      '';
    };

    lookAndFeel = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "org.kde.breezedark.desktop";
      description = ''
        The Plasma look and feel theme. Run plasma-apply-lookandfeel --list for valid options.
      '';
    };

    iconTheme = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "Papirus";
      description = ''
        The Plasma icon theme.
      '';
    };

    wallpaper = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
      example = lib.literalExpression ''"''${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Kay/contents/images/1080x1920.png"'';
      description = ''
        The Plasma wallpaper. Can be either be the path to an image file or a kpackage.
      '';
    };

    wallpaperSlideShow = lib.mkOption {
      type = lib.types.nullOr wallpaperSlideShowType;
      default = null;
      example = lib.literalExpression ''{ path = "''${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/"; }'';
      description = ''
        Allows you to set wallpaper slideshow. Needs a directory of your wallpapers and an interval length.
      '';
    };

    wallpaperPictureOfTheDay = lib.mkOption {
      type = lib.types.nullOr wallpaperPictureOfTheDayType;
      default = null;
      example = { provider = "apod"; };
      description = ''
        Allows you to set wallpaper using the picture of the day plugin. Needs the provider.
      '';
    };

    wallpaperPlainColor = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "0,64,174,256";
      description = ''
        Allows you to set wallpaper using a plain color. Color is a comma-seperated R,G,B,A string. Alpha optional (default is 256).
      '';
    };

    soundTheme = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "freedesktop";
      description = ''
        The sound-theme to use with plasma.
      '';
    };

    splashScreen = {
      engine = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        example = "none";
        description = ''
          The engine for the splash-screen theme. If not specified it will try
          to set an appropriate engine for you, but if this doesn't work you
          might want to manually specify this.
        '';
      };
      theme = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        example = "None";
        description = ''
          The splash-screen theme shown at login. To see available values see the
          Theme key in ~/.config/ksplashrc after applying the splash-screen via
          the settings app. Can also be set to "None" to disable the splash-screen
          altogether.
        '';
      };
    };

    windowDecorations = {
      library = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        example = "org.kde.kwin.aurorae";
        description = ''
          The library for the window decorations theme. To see available values
          see the library key in the org.kde.kdecoration2 section of
          ~/.config/kwinrc after applying the window-decoration via the
          settings app.
        '';
      };
      theme = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        example = "__aurorae__svg__CatppuccinMocha-Modern";
        description = ''
          The window decorations theme. To see available values see the theme key
          in the org.kde.kdecoration2 section of ~/.config/kwinrc after
          applying the window-decoration via the settings app.
        '';
      };
    };

    desktop = {
      icons = {
        arrangement = lib.mkOption {
          type = with lib.types; nullOr (enum [ "leftToRight" "topToBottom" ]);
          default = null;
          example = "topToBottom";
          description = ''
            The direction, in which desktop icons are to be arranged.
          '';
        };

        alignment = lib.mkOption {
          type = with lib.types; nullOr (enum [ "left" "right" ]);
          default = null;
          example = "right";
          description = ''
            Whether to align the icons on the left (the default) or right
            side of the screen.
          '';
        };

        lockInPlace = lib.mkOption {
          type = with lib.types; nullOr bool;
          default = null;
          example = true;
          description = ''
            Locks the position of all desktop icons to the order and placement
            defined by `arrangement`, `alignment` and the `sorting` options
            so they can’t be manually moved.
          '';
        };

        sorting = {
          mode = lib.mkOption {
            type = with lib.types; nullOr (enum (builtins.attrNames desktopIconSortingModeId));
            default = null;
            example = "type";
            description = ''
              Specifies the sort mode for the desktop icons. By default they are
              sorted by name.
            '';
            apply = sortMode: if (sortMode == null) then null else desktopIconSortingModeId.${sortMode};
          };

          descending = lib.mkOption {
            type = with lib.types; nullOr bool;
            default = null;
            example = true;
            description = ''
              Reverses the sorting order if enabled. Sorting is ascending by default.
            '';
          };

          foldersFirst = lib.mkOption {
            type = with lib.types; nullOr bool;
            default = null;
            example = false;
            description = ''
              Folders are sorted separately from files by default. This means
              folders appear first, sorted for example ascending by name,
              followed by files, also sorted ascending by name.
              If this option is disabled, all items are sorted irrespective
              of their type.
            '';
          };
        };

        size = lib.mkOption {
          type = with lib.types; nullOr (ints.between 0 6);
          default = null;
          example = 2;
          description = ''
            The desktop icon size, which is normally configured via a slider
            with seven possible values ranging from small (0) to large (6).
            The fourth position (3) is the default.
          '';
        };

        folderPreviewPopups = lib.mkOption {
          type = with lib.types; nullOr bool;
          default = null;
          example = false;
          description = ''
            Enables the arrow button when hovering over a folder on the desktop
            which shows a preview popup of the folder’s contents.
            Is enabled by default.
          '';
        };

        previewPlugins = lib.mkOption {
          type = with lib.types; nullOr (listOf str);
          default = null;
          example = [ "audiothumbnail" "fontthumbnail" ];
          description = ''
            Configures the preview plugins used to preview desktop files and folders.
          '';
        };
      };

      mouseActions = {
        leftClick = lib.mkOption {
          type = lib.types.nullOr mouseActionNamesEnum;
          default = null;
          example = "appLauncher";
          description = "Action for a left click on the desktop.";
          apply = value: if (value == null) then null else mouseActions.${value};
        };

        middleClick = lib.mkOption {
          type = lib.types.nullOr mouseActionNamesEnum;
          default = null;
          example = "switchWindow";
          description = "Action for a click on the desktop with the middle mouse button.";
          apply = value: if (value == null) then null else mouseActions.${value};
        };

        rightClick = lib.mkOption {
          type = lib.types.nullOr mouseActionNamesEnum;
          default = null;
          example = "contextMenu";
          description = "Action for a right click on the desktop.";
          apply = value: if (value == null) then null else mouseActions.${value};
        };

        verticalScroll = lib.mkOption {
          type = lib.types.nullOr mouseActionNamesEnum;
          default = null;
          example = "switchVirtualDesktop";
          description = "Action for scrolling (vertically) while hovering over the desktop.";
          apply = value: if (value == null) then null else mouseActions.${value};
        };
      };
    };
  };

  config = (lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          let
            wallpapers = with cfg.workspace; [ wallpaperSlideShow wallpaper wallpaperPictureOfTheDay wallpaperPlainColor ];
          in
          lib.count (x: x != null) wallpapers <= 1;
        message = "Can set only one of wallpaper, wallpaperSlideShow, wallpaperPictureOfTheDay, and wallpaperPlainColor.";
      }
      {
        assertion = (cfg.workspace.splashScreen.engine == null || cfg.workspace.splashScreen.theme != null);
        message = ''
          Cannot set plasma.workspace.splashScreen.engine without a
          corresponding theme.
        '';
      }
      {
        assertion = !(lib.xor (cfg.workspace.windowDecorations.theme == null) (cfg.workspace.windowDecorations.library == null));
        message = ''
          Must set both plasma.workspace.windowDecorations.library and
          plasma.workspace.windowDecorations.theme or none.
        '';
      }
    ];
    warnings = (if
      ((cfg.workspace.lookAndFeel != null) &&
        (cfg.workspace.splashScreen.theme != null ||
          cfg.workspace.windowDecorations.theme != null)) then
      [
        ''Setting lookAndFeel together with splashScreen or windowDecorations in
        plasma-manager is not recommended since lookAndFeel themes often
        override these settings. Consider setting each part in the lookAndFeel
        theme manually.''
      ] else [ ]);

    programs.plasma.configFile = (lib.mkMerge [
      {
        kdeglobals = {
          KDE.SingleClick = (lib.mkIf (cfg.workspace.clickItemTo != null) (cfg.workspace.clickItemTo == "open"));
          Sounds.Theme = (lib.mkIf (cfg.workspace.soundTheme != null) cfg.workspace.soundTheme);
        };
        plasmarc = (lib.mkIf (cfg.workspace.tooltipDelay != null) {
          PlasmaToolTips.Delay = cfg.workspace.tooltipDelay;
        });
        kcminputrc = (lib.mkIf (cfg.workspace.cursor != null && cfg.workspace.cursor.size != null) {
          Mouse.cursorSize = cfg.workspace.cursor.size;
        });
        ksplashrc.KSplash = (lib.mkIf (cfg.workspace.splashScreen.theme != null) {
          Engine = (if (cfg.workspace.splashScreen.engine == null) then
            (splashScreenEngineDetect cfg.workspace.splashScreen.theme)
          else cfg.workspace.splashScreen.engine);
          Theme = cfg.workspace.splashScreen.theme;
        });
        kwinrc = (lib.mkIf (cfg.workspace.windowDecorations.theme != null) {
          "org.kde.kdecoration2".library = cfg.workspace.windowDecorations.library;
          "org.kde.kdecoration2".theme = cfg.workspace.windowDecorations.theme;
        });
      }
      # We add persistence to some keys in order to not reset the themes on
      # each generation when we use overrideConfig.
      (lib.mkIf (cfg.overrideConfig && anyThemeSet) (
        let
          colorSchemeIgnore =
            if (cfg.workspace.colorScheme != null || cfg.workspace.lookAndFeel != null) then
              (import ../lib/colorscheme.nix {
                inherit lib;
              }) else { };
        in
        (lib.mkMerge
          [
            {
              kcminputrc.Mouse.cursorTheme.persistent = lib.mkDefault (cfg.workspace.cursor != null && cfg.workspace.cursor.theme != null);
              kdeglobals.General.ColorScheme.persistent = lib.mkDefault (cfg.workspace.colorScheme != null || cfg.workspace.lookAndFeel != null);
              kdeglobals.Icons.Theme.persistent = lib.mkDefault (cfg.workspace.iconTheme != null);
              kdeglobals.KDE.LookAndFeelPackage.persistent = lib.mkDefault (cfg.workspace.lookAndFeel != null);
              plasmarc.Theme.name.persistent = lib.mkDefault (cfg.workspace.theme != null);
            }
            colorSchemeIgnore
          ])
      ))
    ]);

    # We create a script which applies the different theme settings using
    # kde tools. We then run this using an autostart script, where this is
    # run only on the first login (unless overrideConfig is enabled),
    # granted all the commands succeed (until we change the settings again).
    programs.plasma.startup = {
      startupScript."apply_themes" = (lib.mkIf anyThemeSet {
        text = ''
          ${if cfg.workspace.lookAndFeel != null then "plasma-apply-lookandfeel -a ${cfg.workspace.lookAndFeel}" else ""}
          ${if cfg.workspace.theme != null then "plasma-apply-desktoptheme ${cfg.workspace.theme}" else ""}
          ${if (cfg.workspace.cursor != null && cfg.workspace.cursor.theme != null) then
          "plasma-apply-cursortheme ${cfg.workspace.cursor.theme}" +
          (if cfg.workspace.cursor.size != null then " --size ${builtins.toString cfg.workspace.cursor.size}" else "")
          else ""}
          ${if cfg.workspace.colorScheme != null then "plasma-apply-colorscheme ${cfg.workspace.colorScheme}" else ""}
          ${if cfg.workspace.iconTheme != null then "${pkgs.kdePackages.plasma-workspace}/libexec/plasma-changeicons ${cfg.workspace.iconTheme}" else ""}
        '';
        priority = 1;
      });

      desktopScript."set_desktop_folder_settings" = (lib.mkIf anyDesktopFolderSettingsSet {
        text = ''
          // Desktop folder settings
          let allDesktops = desktops();
          for (const desktop of allDesktops) {
            desktop.currentConfigGroup = ["General"];
            ${lib.optionalString (cfg.workspace.desktop.icons.arrangement == "topToBottom") ''desktop.writeConfig("arrangement", 1);''}
            ${lib.optionalString (cfg.workspace.desktop.icons.alignment == "right") ''desktop.writeConfig("alignment", 1);''}
            ${lib.optionalString (cfg.workspace.desktop.icons.lockInPlace == true) ''desktop.writeConfig("locked", true);''}
            ${stringIfNotNull cfg.workspace.desktop.icons.size ''desktop.writeConfig("iconSize", ${builtins.toString cfg.workspace.desktop.icons.size});''}
            ${lib.optionalString (cfg.workspace.desktop.icons.folderPreviewPopups == false) ''desktop.writeConfig("popups", false);''}
            ${stringIfNotNull cfg.workspace.desktop.icons.previewPlugins ''desktop.writeConfig("previewPlugins", "${lib.strings.concatStringsSep "," cfg.workspace.desktop.icons.previewPlugins}");''}
            ${stringIfNotNull cfg.workspace.desktop.icons.sorting.mode ''desktop.writeConfig("sortMode", ${builtins.toString cfg.workspace.desktop.icons.sorting.mode});''}
            ${lib.optionalString (cfg.workspace.desktop.icons.sorting.descending == true) ''desktop.writeConfig("sortDesc", true);''}
            ${lib.optionalString (cfg.workspace.desktop.icons.sorting.foldersFirst == false) ''desktop.writeConfig("sortDirsFirst", false);''}
          }
        '';
        priority = 3;
      });

      desktopScript."set_desktop_mouse_actions" = (lib.mkIf anyDesktopMouseActionsSet {
        text = ''
          // Mouse actions
          let configFile = ConfigFile('plasma-org.kde.plasma.desktop-appletsrc');
          configFile.group = 'ActionPlugins';
          // References the section [ActionPlugins][0].
          let actionPluginSubSection = ConfigFile(configFile, 0)
          ${stringIfNotNull cfg.workspace.desktop.mouseActions.leftClick ''actionPluginSubSection.writeEntry("LeftButton;NoModifier", "${cfg.workspace.desktop.mouseActions.leftClick}");''}
          ${stringIfNotNull cfg.workspace.desktop.mouseActions.middleClick ''actionPluginSubSection.writeEntry("MiddleButton;NoModifier", "${cfg.workspace.desktop.mouseActions.middleClick}");''}
          ${stringIfNotNull cfg.workspace.desktop.mouseActions.rightClick ''actionPluginSubSection.writeEntry("RightButton;NoModifier", "${cfg.workspace.desktop.mouseActions.rightClick}");''}
          ${stringIfNotNull cfg.workspace.desktop.mouseActions.verticalScroll ''actionPluginSubSection.writeEntry("wheel:Vertical;NoModifier", "${cfg.workspace.desktop.mouseActions.verticalScroll}");''}
        '';
        priority = 3;
        restartServices = [ "plasma-plasmashell" ];
      });
    };

    # The wallpaper configuration can be found in panels.nix due to wallpaper
    # configuration and panel configuration being stored in the same file, and
    # thus should be using the same desktop-script.
  });
}

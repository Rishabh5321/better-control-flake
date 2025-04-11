{ lib
, python3Packages
, fetchFromGitHub
, gtk3
, networkmanager
, bluez
, pipewire
, brightnessctl
, power-profiles-daemon
, gammastep
, libpulseaudio
, pulseaudio
, desktop-file-utils
, wrapGAppsHook4
, gobject-introspection
, usbguard
, upower
}:

python3Packages.buildPythonApplication rec {
  pname = "better-control";
  version = "v6.7";
  pyproject = false;

  src = fetchFromGitHub {
    owner = "quantumvoid0";
    repo = "better-control";
    tag = version;
    hash = "sha256-jCtn9rnUUGPk1jNtLWfekC2GKpEVAxY4ETYRClLscTc=";
  };

  nativeBuildInputs = [
    desktop-file-utils
    wrapGAppsHook4
    gobject-introspection
  ];

  buildInputs = [
    gtk3
    libpulseaudio
  ];

  dependencies =
    [
      networkmanager
      bluez
      pipewire
      brightnessctl
      power-profiles-daemon
      gammastep
      pulseaudio
      usbguard
      upower
    ]
    ++ (with python3Packages; [
      pygobject3
      dbus-python
      pydbus
      psutil
      qrcode
      requests
      setproctitle
      pillow
      pycairo
    ]);

  makeFlags = [ "PREFIX=${placeholder "out"}" ];

  dontWrapPythonPrograms = true;

  dontWrapGApps = true;

  makeWrapperArgs = [ "\${gappsWrapperArgs[@]}" ];

postInstall = ''
  rm $out/bin/control
  chmod +x $out/share/better-control/better_control.py
  substituteInPlace $out/bin/better-control \
    --replace-fail "/bin/bash" "/usr/bin/env bash" \
    --replace-fail "python3 " ""
  substituteInPlace $out/share/applications/better-control.desktop \
    --replace-fail "/usr/bin/" ""
    
  # Create a patch for the settings.py file to handle the custom logger
  cat > settings_patch.py << 'EOF'
# Add compatibility for the custom logger
def safe_log(logger, level, message):
    # Try various logging methods
    for method_name in ['log_' + level, level, 'log']:
        if hasattr(logger, method_name):
            method = getattr(logger, method_name)
            if callable(method):
                try:
                    method(message)
                    return
                except:
                    pass
    # Fallback to print if no method works
    print(f"[{level.upper()}] {message}")

# Replace the problematic functions
def save_settings(settings, logging):
    try:
        # Original implementation
        with open(SETTINGS_FILE, 'w') as f:
            json.dump(settings, f, indent=4)
        safe_log(logging, 'info', f"Settings saved successfully to {SETTINGS_FILE}")
    except Exception as e:
        safe_log(logging, 'error', f"Error saving settings: {e}")
EOF

  # Append the patch to the settings.py file
  cat settings_patch.py >> $out/share/better-control/utils/settings.py
'';

  postFixup = ''
    wrapPythonProgramsIn "$out/share/better-control" "$out $pythonPath"
  '';

  meta = {
    description = "System control panel utility";
    homepage = "https://github.com/quantumvoid0/better-control";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ Rishabh5321 ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "better-control";
  };
}

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
  version = "v6.11.7";
  pyproject = false;

  src = fetchFromGitHub {
    owner = "quantumvoid0";
    repo = "better-control";
    tag = version;
    hash = "sha256-eN0VAxZ43I7a0ljh5r04RksHL+x8Em1eD6a/Gi8kczE=";
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
    rm $out/bin/betterctl
    chmod +x $out/share/better-control/better_control.py
    substituteInPlace $out/bin/better-control \
      --replace-fail "/bin/bash" "/usr/bin/env bash" \
      --replace-fail "python3 " ""
    substituteInPlace $out/bin/control \
      --replace-fail "/bin/bash" "/usr/bin/env bash" \
      --replace-fail "python3 " ""
    substituteInPlace $out/share/applications/better-control.desktop \
      --replace-fail "/usr/bin/" ""
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

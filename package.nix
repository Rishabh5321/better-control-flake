{ lib
, python3Packages
, fetchFromGitHub
, gtk3
, bash
, networkmanager
, bluez
, brightnessctl
, power-profiles-daemon
, gammastep
, pulseaudio
, desktop-file-utils
, wrapGAppsHook3
, gobject-introspection
, upower
, nix-update-script
,
}:

python3Packages.buildPythonApplication rec {
  pname = "better-control";
  version = "e9fab511b294c1a7272e38624718dca8f3b6b899";
  pyproject = false;

  src = fetchFromGitHub {
    owner = "better-ecosystem";
    repo = "better-control";
    rev = "${version}";
    hash = "sha256-CGgzBSLo5mFObFJ48a+66VhEHu8W5OtmZzNJXuCnP6A=";
  };

  build-system = with python3Packages; [
    setuptools
  ];

  nativeBuildInputs = [
    desktop-file-utils
    wrapGAppsHook3
    gobject-introspection
  ];

  buildInputs = [
    bash
    gtk3
  ];

  # Check src/utils/dependencies.py
  runtimeDeps = [
    pulseaudio
    networkmanager
    bluez
    brightnessctl
    power-profiles-daemon
    gammastep
    upower
  ];

  dependencies = with python3Packages; [
    pygobject3
    dbus-python
    psutil
    qrcode
    requests
    setproctitle
    pillow
    pycairo
  ];

  makeFlags = [ "PREFIX=${placeholder "out"}" ];

  dontWrapGApps = true;

  makeWrapperArgs = [
    "\${gappsWrapperArgs[@]}"
    "--prefix PATH : ${lib.makeBinPath runtimeDeps}"
  ];

  postInstall = ''
    rm $out/bin/betterctl
    chmod +x $out/share/better-control/better_control.py
    substituteInPlace $out/bin/* \
      --replace-fail "python3 " ""
    substituteInPlace $out/share/applications/better-control.desktop \
      --replace-fail "/usr/bin/" ""
  '';

  # Project has no tests
  doCheck = false;

  postFixup = ''
    wrapPythonProgramsIn "$out/share/better-control" "$out $pythonPath"
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Simple control panel for linux based on GTK";
    homepage = "https://github.com/better-ecosystem/better-control";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ Rishabh5321 ];
    platforms = lib.platforms.linux;
    mainProgram = "control"; # Users use both "control" and "better-control" to launch
  };
}

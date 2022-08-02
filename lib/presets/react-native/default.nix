{ pkgs, config, inputs, lib, ... }: {
  config.preset.base.enable = lib.mkDefault true;
  # cool, huh? "enabled if react-native is enabled and not explicitly disabled"
  config.preset.react.enable = lib.mkDefault config.preset.react-native.enable;
  config.preset.react-native = {
    packages = pkgs: with pkgs; [ sdk gradle jdk yarn ];
    overlays = {
      android = inputs.android.overlay;
      sdk = _: _: {
        sdk = pkgs.androidSdk (sdkPkgs: with sdkPkgs; [
          cmdline-tools-latest
          build-tools-33-0-0
          emulator
          ndk-bundle
          platform-tools
          platforms-android-33
          system-images-android-33-google-apis-x86-64
        ]);
      };
    };
  };
}

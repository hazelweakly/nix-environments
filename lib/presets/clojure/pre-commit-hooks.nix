{ lib, clj-kondo, zprint, ... }: {
  clj-kondo = {
    enable = true;
    name = "clj-kondo";
    description = "Lint Clojure files";
    entry = lib.mkDefault "${clj-kondo}/bin/clj-kondo --parallel --cache false --config .clj-kondo/config.edn --lint";
    types = [ "file" "clojure" ];
    raw.require_serial = true;
  };

  zprint = {
    enable = true;
    name = "zprint";
    description = "Format Clojure files";
    entry = lib.mkDefault "${zprint}/bin/zprint '{:search-config? true}' -fw";
    types = [ "file" "clojure" ];
  };
}

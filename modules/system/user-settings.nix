{ ... }:
let
  name = "zeus";
in
{
  _module.args.userSettings = {
    inherit name;
    home = "/home/${name}";
    group = "users";
  };
}

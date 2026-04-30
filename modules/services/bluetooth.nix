{ pkgs, ... }:

let
  tab = "\t";
  bluezFixed = pkgs.bluez.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      (pkgs.writeText "bluez-skip-empty-default-system-config.patch" ''
        diff --git a/src/adapter.c b/src/adapter.c
        --- a/src/adapter.c
        +++ b/src/adapter.c
        @@ -4964,8 +4964,10 @@ static void load_defaults(struct btd_adapter *adapter)
         ${tab}if (!load_le_defaults(adapter, list, &btd_opts.defaults.le))
         ${tab}${tab}goto done;
        ${" "}
        -${tab}if (mgmt_tlv_list_size(list) == 0)
        -${tab}${tab}goto done;
        +${tab}if (mgmt_tlv_list_size(list) == 0) {
        +${tab}${tab}mgmt_tlv_list_free(list);
        +${tab}${tab}return;
        +${tab}}
        ${" "}
         ${tab}err = mgmt_send_tlv(adapter->mgmt, MGMT_OP_SET_DEF_SYSTEM_CONFIG,
         ${tab}${tab}${tab}adapter->dev_id, list, NULL, NULL, NULL);
      '')
    ];
  });
in

{
  hardware.bluetooth = {
    enable = true;
    package = bluezFixed;
    powerOnBoot = true;
  };
}

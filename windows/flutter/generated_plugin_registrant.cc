//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <i2p_flutter/i2p_flutter_plugin_c_api.h>
#include <objectbox_flutter_libs/objectbox_flutter_libs_plugin.h>
#include <openpgp/openpgp_plugin.h>
#include <permission_handler_windows/permission_handler_windows_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  I2pFlutterPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("I2pFlutterPluginCApi"));
  ObjectboxFlutterLibsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ObjectboxFlutterLibsPlugin"));
  OpenpgpPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("OpenpgpPlugin"));
  PermissionHandlerWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PermissionHandlerWindowsPlugin"));
}

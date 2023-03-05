//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <i2p_flutter/i2p_flutter_plugin.h>
#include <objectbox_flutter_libs/objectbox_flutter_libs_plugin.h>
#include <openpgp/openpgp_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) i2p_flutter_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "I2pFlutterPlugin");
  i2p_flutter_plugin_register_with_registrar(i2p_flutter_registrar);
  g_autoptr(FlPluginRegistrar) objectbox_flutter_libs_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "ObjectboxFlutterLibsPlugin");
  objectbox_flutter_libs_plugin_register_with_registrar(objectbox_flutter_libs_registrar);
  g_autoptr(FlPluginRegistrar) openpgp_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "OpenpgpPlugin");
  openpgp_plugin_register_with_registrar(openpgp_registrar);
}

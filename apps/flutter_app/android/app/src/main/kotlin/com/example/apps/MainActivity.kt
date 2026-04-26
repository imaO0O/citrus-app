package com.example.apps

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.citrus.app/dynamic_icon"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setIcon" -> {
                        val isDark = call.argument<Boolean>("isDark") ?: false
                        try {
                            val packageName = packageName
                            val mainActivity = ComponentName(packageName, "$packageName.MainActivity")
                            val defaultAlias = ComponentName(packageName, "$packageName.DefaultIcon")
                            val darkAlias = ComponentName(packageName, "$packageName.DarkIcon")

                            // Включаем нужный alias, выключаем другой
                            if (isDark) {
                                packageManager.setComponentEnabledSetting(
                                    defaultAlias,
                                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                                    PackageManager.DONT_KILL_APP
                                )
                                packageManager.setComponentEnabledSetting(
                                    darkAlias,
                                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                                    PackageManager.DONT_KILL_APP
                                )
                            } else {
                                packageManager.setComponentEnabledSetting(
                                    darkAlias,
                                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                                    PackageManager.DONT_KILL_APP
                                )
                                packageManager.setComponentEnabledSetting(
                                    defaultAlias,
                                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                                    PackageManager.DONT_KILL_APP
                                )
                            }

                            // Отключаем main activity из лаунчера,
                            // чтобы не было дубликата с alias
                            packageManager.setComponentEnabledSetting(
                                mainActivity,
                                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                                PackageManager.DONT_KILL_APP
                            )

                            result.success(null)
                        } catch (e: Exception) {
                            result.error("ICON_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

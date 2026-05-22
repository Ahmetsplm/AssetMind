import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Bildirim izni durumunu kontrol eder ve gerekirse ister
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    
    final result = await Permission.notification.request();
    return result.isGranted;
  }
  
  /// Bildirim izni sadece durumunu döner
  static Future<bool> isNotificationGranted() async {
    return await Permission.notification.isGranted;
  }

  /// Batarya optimizasyonu (arka plan çalışma) kısıtlamasından çıkma isteği
  static Future<bool> requestBatteryOptimizationBypass() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) return true;
    
    final result = await Permission.ignoreBatteryOptimizations.request();
    return result.isGranted;
  }
  
  /// Batarya optimizasyonu sadece durumunu döner
  static Future<bool> isBatteryOptimizationBypassed() async {
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }
  
  /// Cihaz ayarlarına yönlendirir
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}

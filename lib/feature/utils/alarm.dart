
import 'package:alarm/model/volume_settings.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter_todo_app/constant/files.dart';

class AlarmUtil {
  static Future initialize() async {
    await Alarm.init();
  }

  static void setTodoAlarm(int id, DateTime dateTime, String title, String body) {
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: audioFile,
      loopAudio: true,
      vibrate: true,
      //-> Add this new 2 
      androidFullScreenIntent: true,
      allowAlarmOverlap: true,
      //
      volumeSettings: VolumeSettings.fade(
        volume: 0.8,
        fadeDuration: Duration(seconds: 5),
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: 'Stop Alarm',
        icon: notification_icon,
      ),
    );
    Alarm.set(alarmSettings: alarmSettings);
  }

  static void cancelTodoAlarm(int id) {
    Alarm.stop(id);
  }
}
import 'dart:convert';
import 'dart:math';

import 'package:logger/logger.dart';

class JanusUtil {

  static Logger logger = new Logger();
  static String debugLevel = 'error';

  static vdebug(dynamic msg, [dynamic err, StackTrace stackTrace]) {
    logger.v(msg, err, stackTrace);
  }

  static debug(dynamic msg, [dynamic err, StackTrace stackTrace]) {
    if (debugLevel == 'all' || debugLevel == 'debug')
      logger.d(msg, err, stackTrace);
  }

  static log(dynamic msg, [dynamic err, StackTrace stackTrace]) {
    if (debugLevel == 'all' || debugLevel == 'log')
      logger.i(msg, err, stackTrace);
  }

  static warn(dynamic msg, [dynamic err, StackTrace stackTrace]) {
    if (debugLevel == 'all' || debugLevel == 'warn')
      logger.w(msg, err, stackTrace);
  }

  static error(dynamic msg, [dynamic err, StackTrace stackTrace]) {
    if (debugLevel == 'all' || debugLevel == 'error')
      logger.e(msg, err, stackTrace);
  }

  static trace(dynamic msg, [dynamic err, StackTrace stackTrace]) {
    if (debugLevel == 'all' || debugLevel == 'trace')
      logger.wtf(msg, err, stackTrace);
  }

  static String getRandString(int len) {
    var random = Random.secure();
    var values = List<int>.generate(len, (i) =>  random.nextInt(255));
    return base64UrlEncode(values);
  }
}
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

abstract final class HistoryDateTimeFormat {
  static String date(BuildContext context, DateTime value) {
    return intl.DateFormat.yMMMEd(_localeOf(context)).format(value.toLocal());
  }

  static String time(BuildContext context, DateTime value) {
    return intl.DateFormat.Hm(_localeOf(context)).format(value.toLocal());
  }

  static String _localeOf(BuildContext context) {
    return Localizations.localeOf(context).toString();
  }
}

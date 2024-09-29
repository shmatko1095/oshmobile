import 'package:intl/intl.dart';

String formatDateByDDMMYYYY(DateTime dateTime) {
  return DateFormat("d MMM, yyyy").format(dateTime);
}

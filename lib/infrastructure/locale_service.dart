import 'package:intl/intl.dart';
import 'package:shiori/domain/app_constants.dart';
import 'package:shiori/domain/enums/enums.dart';
import 'package:shiori/domain/extensions/datetime_extensions.dart';
import 'package:shiori/domain/extensions/string_extensions.dart';
import 'package:shiori/domain/models/models.dart';
import 'package:shiori/domain/services/locale_service.dart';
import 'package:shiori/domain/services/settings_service.dart';
import 'package:shiori/domain/utils/date_utils.dart';

class LocaleServiceImpl implements LocaleService {
  final SettingsService _settingsService;

  LocaleServiceImpl(this._settingsService);

  @override
  DateTime getCharBirthDate(String? birthday) {
    if (birthday.isNullEmptyOrWhitespace) {
      throw Exception('Character birthday must not be null');
    }

    if (birthday!.length != 5 || !birthday.contains('/')) {
      throw Exception('Character birthday is not valid');
    }
    final split = birthday.split('/');
    final expectedMonth = int.parse(split.first);
    final expectedDay = int.parse(split.last);

    final int daysInMonth = DateUtils.getLastDayOfMonth(expectedMonth);
    final DateTime now = DateTime.now().getStartingDate();
    DateTime date = DateTime(now.year, expectedMonth, expectedDay);
    if (date.isAfterInclusive(now) && expectedDay <= daysInMonth) {
      return date;
    }

    int attempts = 4;
    date = DateTime(now.year + 1, expectedMonth, expectedDay);
    while (_hasLeapYearOccurred(expectedMonth, expectedDay, date)) {
      date = DateTime(date.year + 1, expectedMonth, expectedDay);
      attempts--;
    }

    if (attempts < 0) {
      throw Exception('The provided date = $birthday could not be parsed');
    }

    return date;
  }

  @override
  String formatCharBirthDate(String? birthday) {
    if (birthday.isNullEmptyOrWhitespace) {
      return '';
    }
    final locale = getFormattedLocale(_settingsService.language);
    final birthdayDate = getCharBirthDate(birthday);
    return toBeginningOfSentenceCase(DateFormat('MMMM d', locale).format(birthdayDate)) ?? '';
  }

  @override
  String getFormattedLocale(AppLanguageType language) {
    final locale = getLocale(language);
    return '${locale.code}_${locale.countryCode}';
  }

  @override
  LanguageModel getLocaleWithoutLang() {
    return getLocale(_settingsService.language);
  }

  @override
  LanguageModel getLocale(AppLanguageType language) {
    if (!languagesMap.entries.any((kvp) => kvp.key == language)) {
      throw Exception('The language = $language is not a valid value');
    }

    return languagesMap.entries.firstWhere((kvp) => kvp.key == language).value;
  }

  @override
  String getDayNameFromDate(DateTime date) {
    final locale = getFormattedLocale(_settingsService.language);
    return DateFormat('EEEE', locale).format(date).toUpperCase();
  }

  @override
  String getDayNameFromDay(int day) {
    final dates = List.generate(7, (index) => DateTime.now().add(Duration(days: index)));

    for (final date in dates) {
      if (date.weekday != day) {
        continue;
      }
      return getDayNameFromDate(date);
    }

    return 'N/A';
  }

  bool _hasLeapYearOccurred(int expectedMonth, int expectedDay, DateTime date) {
    return date.month != expectedMonth || date.day != expectedDay;
  }
}

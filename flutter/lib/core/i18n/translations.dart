import 'package:get/get.dart';

import 'it_IT.dart';
import 'en_US.dart';
import 'fr_FR.dart';
import 'es_ES.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'it_IT': itIT,
    'en_US': enUS,
    'fr_FR': frFR,
    'es_ES': esES,
  };
}

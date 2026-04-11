/// Все тесты Public Domain и могут свободно использоваться

import '../../models/psychological_test.dart';

// Big Five
export 'big_five_ipip50.dart';
export 'big_five_ipip120.dart';

// Клинические шкалы
export 'phq9.dart';
export 'gad7.dart';
export 'dass21.dart';

// Самооценка
export 'rosenberg_self_esteem.dart';

// Тёмная триада
export 'dark_triad_sd3.dart';

// DISC
export 'disc.dart';

// Импорты для реестра
import 'big_five_ipip50.dart' as big_five_ipip50;
import 'big_five_ipip120.dart' as big_five_ipip120;
import 'phq9.dart' as phq9;
import 'gad7.dart' as gad7;
import 'dass21.dart' as dass21;
import 'rosenberg_self_esteem.dart' as rosenberg_self_esteem;
import 'dark_triad_sd3.dart' as dark_triad_sd3;
import 'disc.dart' as disc;

/// Реестр всех доступных тестов
class TestRegistry {
  static final Map<String, PsychologicalTest> _tests = {
    'big_five_ipip_50': big_five_ipip50.BigFiveIPIP50.test,
    'big_five_ipip_120': big_five_ipip120.BigFiveIPIP120.test,
    'phq9': phq9.PHQ9.test,
    'gad7': gad7.Gad7Test.test,
    'dass21': dass21.Dass21Test.test,
    'rosenberg_self_esteem': rosenberg_self_esteem.RosenbergSelfEsteemTest.test,
    'dark_triad_sd3': dark_triad_sd3.DarkTriadSD3Test.test,
    'disc': disc.DISCTest.test,
  };

  /// Получить тест по ID
  static PsychologicalTest? getTest(String testId) => _tests[testId];

  /// Получить все тесты
  static List<PsychologicalTest> getAllTests() => _tests.values.toList();

  /// Получить тесты по категории
  static List<PsychologicalTest> getTestsByCategory(String category) {
    return _tests.values.where((t) => t.category == category).toList();
  }

  /// Категории тестов
  static const Map<String, String> categories = {
    'personality': 'Тесты личности',
    'clinical': 'Клинические шкалы',
    'behavioral': 'Поведенческие тесты',
  };
}

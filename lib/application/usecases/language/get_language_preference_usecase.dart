import 'package:pricecompare/domain/repositories/language_preference_repository.dart';
import 'package:pricecompare/shared/value_objects/app_language.dart';

/// Returns the user's currently saved language preference.
final class GetLanguagePreferenceUseCase {
  const GetLanguagePreferenceUseCase(this._repository);

  final LanguagePreferenceRepository _repository;

  AppLanguage execute() => _repository.get();
}

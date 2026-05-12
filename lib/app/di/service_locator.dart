import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pricecompare/application/usecases/app_info/get_app_info_usecase.dart';
import 'package:pricecompare/application/usecases/debug/get_debug_settings_usecase.dart';
import 'package:pricecompare/application/usecases/debug/set_debug_mode_usecase.dart';
import 'package:pricecompare/application/usecases/debug/set_log_level_usecase.dart';
import 'package:pricecompare/application/usecases/language/get_language_preference_usecase.dart';
import 'package:pricecompare/application/usecases/language/set_language_preference_usecase.dart';
import 'package:pricecompare/application/usecases/product/delete_product_history_usecase.dart';
import 'package:pricecompare/application/usecases/product/delete_product_usecase.dart';
import 'package:pricecompare/application/usecases/product/get_product_histories_usecase.dart';
import 'package:pricecompare/application/usecases/product/get_product_history_usecase.dart';
import 'package:pricecompare/application/usecases/product/get_product_summary_usecase.dart';
import 'package:pricecompare/application/usecases/product/save_product_history_usecase.dart';
import 'package:pricecompare/application/usecases/product/search_products_usecase.dart';
import 'package:pricecompare/application/usecases/theme/get_theme_preference_usecase.dart';
import 'package:pricecompare/application/usecases/theme/set_theme_preference_usecase.dart';
import 'package:pricecompare/domain/repositories/app_info_repository.dart';
import 'package:pricecompare/domain/repositories/debug_settings_repository.dart';
import 'package:pricecompare/domain/repositories/language_preference_repository.dart';
import 'package:pricecompare/domain/repositories/product_repository.dart';
import 'package:pricecompare/domain/repositories/theme_preference_repository.dart';
import 'package:pricecompare/infrastructure/db/sqlite/app_database.dart';
import 'package:pricecompare/infrastructure/db/sqlite/dao/product_dao.dart';
import 'package:pricecompare/infrastructure/db/sqlite/dao/product_history_dao.dart';
import 'package:pricecompare/infrastructure/logging/persistent_app_logger.dart';
import 'package:pricecompare/infrastructure/repositories/package_info_app_info_repository.dart';
import 'package:pricecompare/infrastructure/repositories/shared_preferences_debug_settings_repository.dart';
import 'package:pricecompare/infrastructure/repositories/shared_preferences_language_preference_repository.dart';
import 'package:pricecompare/infrastructure/repositories/shared_preferences_theme_preference_repository.dart';
import 'package:pricecompare/infrastructure/repositories/sqlite_product_repository.dart';
import 'package:pricecompare/presentation/viewmodels/about_viewmodel.dart';
import 'package:pricecompare/presentation/viewmodels/compare_viewmodel.dart';
import 'package:pricecompare/presentation/viewmodels/debug_settings_viewmodel.dart';
import 'package:pricecompare/presentation/viewmodels/debug_viewmodel.dart';
import 'package:pricecompare/presentation/viewmodels/history_detail_viewmodel.dart';
import 'package:pricecompare/presentation/viewmodels/language_viewmodel.dart';
import 'package:pricecompare/presentation/viewmodels/product_detail_viewmodel.dart';
import 'package:pricecompare/presentation/viewmodels/product_list_viewmodel.dart';
import 'package:pricecompare/presentation/viewmodels/theme_viewmodel.dart';
import 'package:pricecompare/shared/logging/app_logger.dart';

final GetIt sl = GetIt.instance;

/// Wires up all dependencies. Call once at app startup before [runApp].
Future<void> setupServiceLocator() async {
  // ─── Infrastructure singletons ───────────────────────────────────────

  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // ignore: avoid_print — logger not yet available
  print('[DI] SharedPreferences ready');

  // ─── Debug settings repository (needed before logger init) ──────────
  final debugSettingsRepo = SharedPreferencesDebugSettingsRepository(prefs);
  sl.registerSingleton<DebugSettingsRepository>(debugSettingsRepo);

  // Logging — restore saved level so filtering is correct from first log
  final logger = PersistentAppLogger();
  await logger.init(savedLevel: debugSettingsRepo.getMinLogLevel());
  sl.registerSingleton<AppLogger>(logger);
  logger.info('[DI] Logger ready (minLevel: ${logger.minLevel.name})');

  // ─── Repository bindings ─────────────────────────────────────────────

  sl.registerSingleton<ThemePreferenceRepository>(
    SharedPreferencesThemePreferenceRepository(prefs),
  );

  sl.registerSingleton<LanguagePreferenceRepository>(
    SharedPreferencesLanguagePreferenceRepository(prefs),
  );

  sl.registerSingleton<AppInfoRepository>(
    const PackageInfoAppInfoRepository(),
  );

  // ─── Use cases ───────────────────────────────────────────────────────

  sl.registerFactory<GetThemePreferenceUseCase>(
    () => GetThemePreferenceUseCase(sl<ThemePreferenceRepository>()),
  );
  sl.registerFactory<SetThemePreferenceUseCase>(
    () => SetThemePreferenceUseCase(sl<ThemePreferenceRepository>()),
  );
  sl.registerFactory<GetLanguagePreferenceUseCase>(
    () => GetLanguagePreferenceUseCase(sl<LanguagePreferenceRepository>()),
  );
  sl.registerFactory<SetLanguagePreferenceUseCase>(
    () => SetLanguagePreferenceUseCase(sl<LanguagePreferenceRepository>()),
  );
  sl.registerFactory<GetAppInfoUseCase>(
    () => GetAppInfoUseCase(sl<AppInfoRepository>()),
  );
  sl.registerFactory<GetDebugSettingsUseCase>(
    () => GetDebugSettingsUseCase(sl<DebugSettingsRepository>()),
  );
  sl.registerFactory<SetDebugModeUseCase>(
    () => SetDebugModeUseCase(sl<DebugSettingsRepository>()),
  );
  sl.registerFactory<SetLogLevelUseCase>(
    () => SetLogLevelUseCase(sl<DebugSettingsRepository>(), sl<AppLogger>()),
  );

  // ─── ViewModels ──────────────────────────────────────────────────────

  sl.registerSingleton<ThemeViewModel>(
    ThemeViewModel(
      sl<GetThemePreferenceUseCase>(),
      sl<SetThemePreferenceUseCase>(),
    ),
  );
  sl.registerSingleton<LanguageViewModel>(
    LanguageViewModel(
      sl<GetLanguagePreferenceUseCase>(),
      sl<SetLanguagePreferenceUseCase>(),
    ),
  );
  sl.registerSingleton<DebugSettingsViewModel>(
    DebugSettingsViewModel(
      sl<GetDebugSettingsUseCase>(),
      sl<SetDebugModeUseCase>(),
      sl<SetLogLevelUseCase>(),
    ),
  );
  sl.registerFactory<AboutViewModel>(
    () => AboutViewModel(sl<GetAppInfoUseCase>()),
  );
  sl.registerFactory<DebugViewModel>(
    () => DebugViewModel(sl<GetAppInfoUseCase>(), sl<AppLogger>()),
  );

  // ─── Infrastructure (DB, Repositories) ──────────────────────────────

  final appDb = AppDatabase.instance;
  await appDb.init();
  sl<AppLogger>().info('[DI] AppDatabase ready');

  final productDao = ProductDao(appDb.db);
  final historyDao = ProductHistoryDao(appDb.db);

  sl.registerSingleton<ProductRepository>(
    SqliteProductRepository(
      productDao: productDao,
      historyDao: historyDao,
    ),
  );

  // ─── Product use cases ───────────────────────────────────────────────

  sl.registerFactory<SaveProductHistoryUseCase>(
    () => SaveProductHistoryUseCase(sl<ProductRepository>()),
  );
  sl.registerFactory<SearchProductsUseCase>(
    () => SearchProductsUseCase(sl<ProductRepository>()),
  );
  sl.registerFactory<GetProductHistoriesUseCase>(
    () => GetProductHistoriesUseCase(sl<ProductRepository>()),
  );
  sl.registerFactory<GetProductHistoryUseCase>(
    () => GetProductHistoryUseCase(sl<ProductRepository>()),
  );
  sl.registerFactory<DeleteProductUseCase>(
    () => DeleteProductUseCase(sl<ProductRepository>()),
  );
  sl.registerFactory<DeleteProductHistoryUseCase>(
    () => DeleteProductHistoryUseCase(sl<ProductRepository>()),
  );
  sl.registerFactory<GetProductSummaryUseCase>(
    () => GetProductSummaryUseCase(sl<ProductRepository>()),
  );

  // ─── Product ViewModels ──────────────────────────────────────────────

  // Lazy singletons so tab state persists across navigation
  sl.registerLazySingleton<CompareViewModel>(
    () => CompareViewModel(
      sl<SaveProductHistoryUseCase>(),
    ),
  );
  sl.registerLazySingleton<ProductListViewModel>(
    () => ProductListViewModel(
      sl<SearchProductsUseCase>(),
      sl<DeleteProductUseCase>(),
      sl<ProductRepository>(),
    ),
  );

  // Factories: created fresh per navigation push
  sl.registerFactory<ProductDetailViewModel>(
    () => ProductDetailViewModel(
      sl<GetProductHistoriesUseCase>(),
      sl<DeleteProductHistoryUseCase>(),
    ),
  );
  sl.registerFactory<HistoryDetailViewModel>(
    () => HistoryDetailViewModel(
      sl<GetProductHistoryUseCase>(),
      sl<DeleteProductHistoryUseCase>(),
    ),
  );

  sl<AppLogger>().info('[DI] Service locator setup complete');
}

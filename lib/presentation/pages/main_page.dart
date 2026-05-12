import 'package:flutter/material.dart';
import 'package:pricecompare/app/di/service_locator.dart';
import 'package:pricecompare/presentation/pages/compare_page.dart';
import 'package:pricecompare/presentation/pages/product_list_page.dart';
import 'package:pricecompare/presentation/viewmodels/debug_settings_viewmodel.dart';
import 'package:pricecompare/presentation/viewmodels/language_viewmodel.dart';
import 'package:pricecompare/presentation/viewmodels/theme_viewmodel.dart';
import 'package:pricecompare/presentation/widgets/ui/widgets.dart';
import 'package:pricecompare/shared/l10n/app_localizations.dart';
import 'package:pricecompare/shared/logging/log_level.dart';
import 'package:pricecompare/shared/theme/theme.dart';
import 'package:pricecompare/shared/value_objects/app_language.dart';

/// Main screen with bottom navigation (Compare / Products).
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = <_TabItem>[
      _TabItem(
        label: l10n.navCompare,
        icon: Icons.compare_arrows_outlined,
        selectedIcon: Icons.compare_arrows,
      ),
      _TabItem(
        label: l10n.navProducts,
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
      ),
    ];
    final tabTitles = [l10n.navCompare, l10n.navProducts];
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selectedIndex = 0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(tabTitles[_selectedIndex]),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              tooltip: l10n.commonMenu,
            ),
          ),
        ),
        drawer: ListenableBuilder(
          listenable: sl<DebugSettingsViewModel>(),
          builder: (context, _) {
            final debugEnabled = sl<DebugSettingsViewModel>().debugEnabled;
            return AppDrawer(
              appName: l10n.appName,
              headerSubtitle: l10n.appTagline,
              items: [
                AppDrawerItem(
                  label: l10n.navCompare,
                  icon: Icons.compare_arrows_outlined,
                  isSelected: _selectedIndex == 0,
                  onTap: () {
                    setState(() => _selectedIndex = 0);
                    Navigator.of(context).pop();
                  },
                ),
                AppDrawerItem(
                  label: l10n.navProducts,
                  icon: Icons.inventory_2_outlined,
                  isSelected: _selectedIndex == 1,
                  onTap: () {
                    setState(() => _selectedIndex = 1);
                    Navigator.of(context).pop();
                  },
                ),
                const AppDrawerItem.divider(),
                AppDrawerItem(
                  label: l10n.navSettings,
                  icon: Icons.settings_outlined,
                  onTap: () {
                    Navigator.of(context).pop();
                    _showSettings(context);
                  },
                ),
                const AppDrawerItem.divider(),
              ],
              bottomItems: [
                AppDrawerItem(
                  label: l10n.drawerAbout,
                  icon: Icons.info_outline,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/about');
                  },
                ),
                AppDrawerItem(
                  label: l10n.drawerLicenses,
                  icon: Icons.description_outlined,
                  onTap: () {
                    Navigator.of(context).pop();
                    openAppLicensePage(context);
                  },
                ),
                if (debugEnabled) ...[
                  AppDrawerItem(
                    label: l10n.drawerLogs,
                    icon: Icons.list_alt_outlined,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/logs');
                    },
                  ),
                  AppDrawerItem(
                    label: l10n.drawerDebug,
                    icon: Icons.bug_report_outlined,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/debug');
                    },
                  ),
                ],
              ],
            );
          },
        ),
        body: _buildTabContent(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: tabs
              .map(
                (tab) => NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon),
                  label: tab.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return switch (_selectedIndex) {
      0 => const ComparePage(),
      1 => const ProductListPage(),
      _ => const ComparePage(),
    };
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SettingsSheet(),
    );
  }
}

// ─── Settings bottom sheet ────────────────────────────────────────────────────

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeViewModel = sl<ThemeViewModel>();
    final languageViewModel = sl<LanguageViewModel>();
    final debugViewModel = sl<DebugSettingsViewModel>();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(AppSpacing.pageMargin),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: AppRadius.fullBorder,
              ),
            ),
          ),
          AppSectionHeader(title: l10n.settingsTitle),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(title: l10n.settingsTheme),
          const SizedBox(height: AppSpacing.sm),
          ListenableBuilder(
            listenable: themeViewModel,
            builder: (context, _) => AppCard(
              child: Column(
                children: [
                  _ThemeOptionTile(
                    label: l10n.settingsThemeLight,
                    icon: Icons.light_mode_outlined,
                    value: ThemeMode.light,
                    groupValue: themeViewModel.themeMode,
                    onChanged: themeViewModel.setThemeMode,
                  ),
                  const Divider(height: 1),
                  _ThemeOptionTile(
                    label: l10n.settingsThemeDark,
                    icon: Icons.dark_mode_outlined,
                    value: ThemeMode.dark,
                    groupValue: themeViewModel.themeMode,
                    onChanged: themeViewModel.setThemeMode,
                  ),
                  const Divider(height: 1),
                  _ThemeOptionTile(
                    label: l10n.settingsThemeSystem,
                    icon: Icons.brightness_auto_outlined,
                    value: ThemeMode.system,
                    groupValue: themeViewModel.themeMode,
                    onChanged: themeViewModel.setThemeMode,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(title: l10n.settingsLanguage),
          const SizedBox(height: AppSpacing.sm),
          ListenableBuilder(
            listenable: languageViewModel,
            builder: (context, _) => AppCard(
              child: Column(
                children: [
                  _LanguageOptionTile(
                    label: l10n.settingsLanguageSystem,
                    icon: Icons.language_outlined,
                    value: AppLanguage.system,
                    groupValue: languageViewModel.language,
                    onChanged: languageViewModel.setLanguage,
                  ),
                  const Divider(height: 1),
                  _LanguageOptionTile(
                    label: l10n.settingsLanguageEnglish,
                    icon: Icons.translate_outlined,
                    value: AppLanguage.english,
                    groupValue: languageViewModel.language,
                    onChanged: languageViewModel.setLanguage,
                  ),
                  const Divider(height: 1),
                  _LanguageOptionTile(
                    label: l10n.settingsLanguageJapanese,
                    icon: Icons.translate_outlined,
                    value: AppLanguage.japanese,
                    groupValue: languageViewModel.language,
                    onChanged: languageViewModel.setLanguage,
                  ),
                ],
              ),
            ),
          ),
          ListenableBuilder(
            listenable: debugViewModel,
            builder: (context, _) {
              if (!debugViewModel.debugEnabled) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  AppSectionHeader(title: l10n.settingsDeveloper),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: debugViewModel.debugEnabled,
                          onChanged: debugViewModel.setDebugEnabled,
                          secondary: Icon(
                            Icons.bug_report_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          title: Text(
                            l10n.settingsDebugMode,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            l10n.settingsDebugModeSubtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.componentPadding,
                            vertical: AppSpacing.xs,
                          ),
                        ),
                        const Divider(height: 1),
                        _LogLevelTile(
                          currentLevel: debugViewModel.logLevel,
                          onChanged: debugViewModel.setLogLevel,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppListCard(
            title: l10n.settingsAbout,
            leading: const Icon(Icons.info_outline),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/about');
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppListCard(
            title: l10n.settingsLicenses,
            leading: const Icon(Icons.description_outlined),
            onTap: () {
              Navigator.of(context).pop();
              openAppLicensePage(context);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Shared option tiles ──────────────────────────────────────────────────────

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: selected ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : Icon(Icons.radio_button_unchecked,
              color: colorScheme.onSurfaceVariant),
      onTap: () => onChanged(value),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.componentPadding,
        vertical: AppSpacing.xs,
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final AppLanguage value;
  final AppLanguage groupValue;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: selected ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : Icon(Icons.radio_button_unchecked,
              color: colorScheme.onSurfaceVariant),
      onTap: () => onChanged(value),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.componentPadding,
        vertical: AppSpacing.xs,
      ),
    );
  }
}

class _LogLevelTile extends StatelessWidget {
  const _LogLevelTile({
    required this.currentLevel,
    required this.onChanged,
  });

  final LogLevel currentLevel;
  final ValueChanged<LogLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final levels = <(LogLevel, String)>[
      (LogLevel.verbose, l10n.logLevelVerbose),
      (LogLevel.debug, l10n.logLevelDebug),
      (LogLevel.info, l10n.logLevelInfo),
      (LogLevel.warning, l10n.logLevelWarning),
      (LogLevel.error, l10n.logLevelError),
    ];
    return ListTile(
      leading: Icon(Icons.tune_outlined, color: colorScheme.onSurfaceVariant),
      title: Text(
        l10n.settingsLogLevel,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: DropdownButton<LogLevel>(
        value: currentLevel,
        underline: const SizedBox.shrink(),
        onChanged: (level) {
          if (level != null) onChanged(level);
        },
        items: levels
            .map(
              (entry) => DropdownMenuItem(
                value: entry.$1,
                child: Text(entry.$2),
              ),
            )
            .toList(),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.componentPadding,
        vertical: AppSpacing.xs,
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

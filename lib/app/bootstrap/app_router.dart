import 'package:flutter/material.dart';
import 'package:pricecompare/app/di/service_locator.dart';
import 'package:pricecompare/domain/entities/product.dart';
import 'package:pricecompare/domain/entities/product_history.dart';
import 'package:pricecompare/domain/repositories/product_repository.dart';
import 'package:pricecompare/presentation/pages/history_detail_page.dart';
import 'package:pricecompare/presentation/pages/main_page.dart';
import 'package:pricecompare/presentation/pages/product_detail_page.dart';
import 'package:pricecompare/presentation/pages/system/about_page.dart';
import 'package:pricecompare/presentation/pages/system/debug_page.dart';
import 'package:pricecompare/presentation/pages/system/logs_page.dart';
import 'package:pricecompare/shared/l10n/app_localizations.dart';
import 'package:pricecompare/shared/logging/app_logger.dart';

/// Named route definitions.
class AppRouter {
  AppRouter._();

  static const String main = '/';
  static const String about = '/about';
  static const String debug = '/debug';
  static const String logs = '/logs';
  static const String productDetail = '/product-detail';
  static const String productByName = '/product-by-name';
  static const String historyDetail = '/history-detail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    sl<AppLogger>().debug('[Router] → ${settings.name}');
    return switch (settings.name) {
      main => MaterialPageRoute<void>(
          builder: (_) => const MainPage(),
          settings: settings,
        ),
      about => MaterialPageRoute<void>(
          builder: (_) => const AboutPage(),
          settings: settings,
        ),
      debug => MaterialPageRoute<void>(
          builder: (_) => const DebugPage(),
          settings: settings,
        ),
      logs => MaterialPageRoute<void>(
          builder: (_) => const LogsPage(),
          settings: settings,
        ),
      productDetail => MaterialPageRoute<void>(
          builder: (_) => ProductDetailPage(
            product: settings.arguments! as Product,
          ),
          settings: settings,
        ),
      productByName => MaterialPageRoute<void>(
          builder: (_) => _ProductByNamePage(
            name: settings.arguments! as String,
          ),
          settings: settings,
        ),
      historyDetail => MaterialPageRoute<void>(
          builder: (_) => HistoryDetailPage(
            history: settings.arguments! as ProductHistory,
          ),
          settings: settings,
        ),
      _ => MaterialPageRoute<void>(
          builder: (_) => const _NotFoundPage(),
          settings: settings,
        ),
    };
  }
}

/// Resolves a product by name and navigates to its detail page.
class _ProductByNamePage extends StatefulWidget {
  const _ProductByNamePage({required this.name});

  final String name;

  @override
  State<_ProductByNamePage> createState() => _ProductByNamePageState();
}

class _ProductByNamePageState extends State<_ProductByNamePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final repo = sl<ProductRepository>();
    final product = await repo.findByName(widget.name);
    if (!mounted) return;
    if (product != null) {
      Navigator.of(context).pushReplacementNamed(
        AppRouter.productDetail,
        arguments: product,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.commonPageNotFound)),
      body: Center(child: Text(l10n.commonNotFound)),
    );
  }
}

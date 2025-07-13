import 'package:flutter/material.dart';

/// Widget réutilisable pour ajouter la fonctionnalité de pull-to-refresh
/// à n'importe quelle page de l'application
class RefreshableWidget extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? backgroundColor;
  final Color? color;

  const RefreshableWidget({
    super.key,
    required this.child,
    required this.onRefresh,
    this.backgroundColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: backgroundColor ?? Colors.white,
      color: color ?? Theme.of(context).primaryColor,
      child: child,
    );
  }
}

/// Widget spécialisé pour les pages avec CustomScrollView
class RefreshableScrollView extends StatelessWidget {
  final List<Widget> slivers;
  final Future<void> Function() onRefresh;
  final Color? backgroundColor;
  final Color? color;

  const RefreshableScrollView({
    super.key,
    required this.slivers,
    required this.onRefresh,
    this.backgroundColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: backgroundColor ?? Colors.white,
      color: color ?? Theme.of(context).primaryColor,
      child: CustomScrollView(
        slivers: slivers,
      ),
    );
  }
}

/// Widget spécialisé pour les pages avec ListView
class RefreshableListView extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function() onRefresh;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? color;

  const RefreshableListView({
    super.key,
    required this.children,
    required this.onRefresh,
    this.padding,
    this.backgroundColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: backgroundColor ?? Colors.white,
      color: color ?? Theme.of(context).primaryColor,
      child: ListView(
        padding: padding,
        children: children,
      ),
    );
  }
}

/// Widget spécialisé pour les pages avec GridView
class RefreshableGridView extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function() onRefresh;
  final SliverGridDelegate gridDelegate;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? color;

  const RefreshableGridView({
    super.key,
    required this.children,
    required this.onRefresh,
    required this.gridDelegate,
    this.padding,
    this.backgroundColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: backgroundColor ?? Colors.white,
      color: color ?? Theme.of(context).primaryColor,
      child: GridView.builder(
        padding: padding,
        gridDelegate: gridDelegate,
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
} 
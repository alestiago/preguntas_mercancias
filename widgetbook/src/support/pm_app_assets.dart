import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Lets `pm_app` widgets load their own assets inside Widgetbook.
///
/// `pm_app` refers to its assets as `assets/...`, which is right when it runs
/// as the app. Here it is a dependency, so Flutter bundles those files under
/// `packages/pm_app/assets/...`. This bundle adds the prefix.
class PmAppAssets extends StatelessWidget {
  const PmAppAssets({super.key, required this.child});

  static final _bundle = _PackagePrefixAssetBundle(rootBundle, 'pm_app');

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DefaultAssetBundle(bundle: _bundle, child: child);
  }
}

class _PackagePrefixAssetBundle extends CachingAssetBundle {
  _PackagePrefixAssetBundle(this._parent, this._package);

  final AssetBundle _parent;
  final String _package;

  String _resolve(String key) =>
      key.startsWith('assets/') ? 'packages/$_package/$key' : key;

  @override
  Future<ByteData> load(String key) => _parent.load(_resolve(key));
}

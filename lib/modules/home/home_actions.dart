import 'package:crust/modules/home/models/store.dart';

class FetchStoresRequest {}

class FetchStoresSuccess {
  final List<Store> stores;

  FetchStoresSuccess(this.stores);

  @override
  String toString() {
    return 'FetchStoresSuccess{stores: $stores}';
  }
}

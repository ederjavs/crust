import 'package:crust/models/store.dart' as MyStore;
import 'package:crust/state/store/store_actions.dart';
import 'package:crust/state/store/store_state.dart';
import 'package:redux/redux.dart';

Reducer<StoreState> storeReducer = combineReducers([
  new TypedReducer<StoreState, FetchStoreSuccess>(fetchStoreSuccess),
  new TypedReducer<StoreState, FetchStoresSuccess>(fetchStoresSuccess),
  new TypedReducer<StoreState, FetchPostsByStoreIdSuccess>(fetchPostsByStoreIdSuccess),
]);

StoreState fetchStoreSuccess(StoreState state, FetchStoreSuccess action) {
  return state.addStore(action.store);
}

StoreState fetchStoresSuccess(StoreState state, FetchStoresSuccess action) {
  return state.addStores(action.stores);
}

StoreState fetchPostsByStoreIdSuccess(StoreState state, FetchPostsByStoreIdSuccess action) {
  return state.addStores(List<MyStore.Store>.from([state.stores[action.storeId].copyWith(posts: action.posts)]));
}

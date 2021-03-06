import 'package:crust/state/app/app_state.dart';
import 'package:crust/state/error/error_actions.dart';
import 'package:crust/state/reward/reward_actions.dart';
import 'package:crust/state/reward/reward_service.dart';
import 'package:redux/redux.dart';

List<Middleware<AppState>> createRewardMiddleware([
  RewardService service = const RewardService(),
]) {
  final fetchRewards = _fetchRewards(service);

  return [
    TypedMiddleware<AppState, FetchRewardsRequested>(fetchRewards),
  ];
}

Middleware<AppState> _fetchRewards(RewardService service) {
  return (Store<AppState> store, action, NextDispatcher next) {
    service.fetchRewards().then(
      (rewards) {
        store.dispatch(FetchRewardsSuccess(rewards));
      },
    ).catchError((e) => store.dispatch(RequestFailure(e.toString())));

    next(action);
  };
}

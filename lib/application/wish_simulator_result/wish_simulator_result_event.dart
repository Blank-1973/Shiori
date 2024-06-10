part of 'wish_simulator_result_bloc.dart';

@freezed
class WishSimulatorResultEvent with _$WishSimulatorResultEvent {
  const factory WishSimulatorResultEvent.init({
    required int bannerIndex,
    required int pulls,
    required WishSimulatorBannerItemsPerPeriodModel period,
  }) = _Init;
}

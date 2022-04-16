import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shiori/domain/models/models.dart';
import 'package:shiori/domain/services/genshin_service.dart';
import 'package:shiori/domain/services/telemetry_service.dart';

part 'banner_history_item_bloc.freezed.dart';
part 'banner_history_item_event.dart';
part 'banner_history_item_state.dart';

class BannerHistoryItemBloc extends Bloc<BannerHistoryItemEvent, BannerHistoryItemState> {
  final GenshinService _genshinService;
  final TelemetryService _telemetryService;

  BannerHistoryItemBloc(this._genshinService, this._telemetryService) : super(const BannerHistoryItemState.loading());

  @override
  Stream<BannerHistoryItemState> mapEventToState(BannerHistoryItemEvent event) async* {
    final s = await event.map(
      init: (e) => _init(e.version),
    );

    yield s;
  }

  Future<BannerHistoryItemState> _init(double version) async {
    await _telemetryService.trackBannerHistoryItemOpened(version);
    final banners = _genshinService.getBanners(version);
    return BannerHistoryItemState.loadedState(version: version, items: banners);
  }
}

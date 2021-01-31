import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genshindb/domain/app_constants.dart';
import 'package:genshindb/domain/assets.dart';
import 'package:genshindb/domain/models/models.dart';
import 'package:genshindb/domain/services/genshin_service.dart';
import 'package:genshindb/domain/services/telemetry_service.dart';

part 'artifact_details_bloc.freezed.dart';
part 'artifact_details_event.dart';
part 'artifact_details_state.dart';

class ArtifactDetailsBloc extends Bloc<ArtifactDetailsEvent, ArtifactDetailsState> {
  final GenshinService _genshinService;
  final TelemetryService _telemetryService;

  ArtifactDetailsBloc(this._genshinService, this._telemetryService) : super(const ArtifactDetailsState.loading());

  @override
  Stream<ArtifactDetailsState> mapEventToState(
    ArtifactDetailsEvent event,
  ) async* {
    yield const ArtifactDetailsState.loading();

    final s = await event.map(
      loadArtifact: (e) async {
        await _telemetryService.trackArtifactLoaded(e.key);
        final artifact = _genshinService.getArtifact(e.key);
        final translation = _genshinService.getArtifactTranslation(e.key);
        final charImgs = _genshinService.getCharactersImgUsingArtifact(e.key);

        var image = artifact.image.split('.png').first;
        image = image.substring(0, image.length - 1);

        return ArtifactDetailsState.loaded(
          name: translation.name,
          image: artifact.fullImagePath,
          rarityMin: artifact.rarityMin,
          rarityMax: artifact.rarityMax,
          bonus: translation.bonus.map((t) {
            final pieces = artifact.bonus.firstWhere((b) => b.key == t.key).pieces;
            return ArtifactCardBonusModel(pieces: pieces, bonus: t.bonus);
          }).toList(),
          images:
              translation.bonus.length == 1 ? [artifact.fullImagePath] : artifactOrder.map((e) => Assets.getArtifactPath('$image$e.png')).toList(),
          charImages: charImgs,
        );
      },
    );

    yield s;
  }
}

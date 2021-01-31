import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:genshindb/application/bloc.dart';
import 'package:genshindb/domain/models/models.dart';
import 'package:genshindb/presentation/artifact/artifact_details_page.dart';
import 'package:genshindb/presentation/shared/extensions/rarity_extensions.dart';
import 'package:genshindb/presentation/shared/gradient_card.dart';
import 'package:genshindb/presentation/shared/rarity.dart';
import 'package:genshindb/presentation/shared/styles.dart';
import 'package:transparent_image/transparent_image.dart';

import 'artifact_stats.dart';

class ArtifactCard extends StatelessWidget {
  final String keyName;
  final String name;
  final String image;
  final int rarity;
  final List<ArtifactCardBonusModel> bonus;
  final double imgWidth;
  final double imgHeight;
  final bool withoutDetails;

  const ArtifactCard({
    Key key,
    @required this.keyName,
    @required this.name,
    @required this.image,
    @required this.rarity,
    @required this.bonus,
    this.imgWidth = 140,
    this.imgHeight = 120,
  })  : withoutDetails = false,
        super(key: key);

  const ArtifactCard.withoutDetails({
    Key key,
    @required this.keyName,
    @required this.name,
    @required this.image,
    @required this.rarity,
  })  : imgWidth = 70,
        imgHeight = 60,
        bonus = const [],
        withoutDetails = true,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _gotoDetailPage(context),
      child: GradientCard(
        shape: Styles.mainCardShape,
        elevation: Styles.cardTenElevation,
        gradient: rarity.getRarityGradient(),
        child: Padding(
          padding: Styles.edgeInsetAll5,
          child: Column(
            children: [
              FadeInImage(
                width: imgWidth,
                height: imgHeight,
                placeholder: MemoryImage(kTransparentImage),
                image: AssetImage(image),
              ),
              if (!withoutDetails)
                Center(
                  child: Tooltip(
                    message: name,
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.subtitle1.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              Rarity(stars: rarity),
              if (bonus.isNotEmpty) ArtifactStats(bonus: bonus),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _gotoDetailPage(BuildContext context) async {
    context.read<ArtifactDetailsBloc>().add(ArtifactDetailsEvent.loadArtifact(key: keyName));
    final route = MaterialPageRoute(builder: (ctx) => ArtifactDetailsPage());
    await Navigator.of(context).push(route);
  }
}

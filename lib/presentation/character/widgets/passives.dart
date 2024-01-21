part of '../character_page.dart';

class _Passives extends StatefulWidget {
  final Color color;
  final List<CharacterPassiveTalentModel> passives;
  final bool expanded;

  const _Passives({
    required this.color,
    required this.passives,
    this.expanded = false,
  });

  @override
  State<_Passives> createState() => _PassivesState();
}

class _PassivesState extends State<_Passives> {
  final List<bool> _isOpen = [];

  @override
  void initState() {
    _isOpen.clear();
    _isOpen.addAll(List.generate(widget.passives.length, (index) => widget.expanded));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return DetailSection.complex(
      title: s.passives,
      color: widget.color,
      children: [
        ExpansionPanelList(
          expansionCallback: (index, isOpen) => setState(() {
            _isOpen[index] = isOpen;
          }),
          dividerColor: Colors.transparent,
          elevation: 0,
          expandIconColor: widget.color,
          expandedHeaderPadding: EdgeInsets.zero,
          materialGapSize: 5,
          children: widget.passives
              .mapIndex(
                (e, i) => ExpansionPanel(
                  isExpanded: _isOpen[i],
                  canTapOnHeader: true,
                  headerBuilder: (context, isOpen) => _PassiveTile(color: widget.color, passive: e),
                  body: _PassiveBody(color: widget.color, passive: e),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PassiveTile extends StatelessWidget {
  final Color color;
  final CharacterPassiveTalentModel passive;

  const _PassiveTile({
    required this.color,
    required this.passive,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    const double iconSize = 50;
    final unlockedAt = passive.unlockedAt >= 1 ? s.unlockedAtAscensionLevelX(passive.unlockedAt) : s.unlockedAutomatically;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: color,
        child: Padding(
          padding: Styles.edgeInsetAll5,
          child: ClipOval(
            child: passive.image == Assets.noImageAvailablePath
                ? Image.asset(passive.image, width: iconSize, height: iconSize, fit: BoxFit.cover)
                : Image.file(File(passive.image), width: iconSize, fit: BoxFit.cover),
          ),
        ),
      ),
      title: Text(passive.title),
      subtitle: Text(unlockedAt),
      horizontalTitleGap: 5,
      iconColor: color,
      minVerticalPadding: 0,
      subtitleTextStyle: theme.textTheme.bodyMedium!.copyWith(color: color),
    );
  }
}

class _PassiveBody extends StatelessWidget {
  final Color color;
  final CharacterPassiveTalentModel passive;

  const _PassiveBody({required this.color, required this.passive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Styles.edgeInsetHorizontal16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomDivider.zeroIndent(color: color, drawShape: false),
          Text(
            passive.description.removeLineBreakAtEnd()!,
          ),
          if (passive.descriptions.isNotEmpty)
            BulletList(
              items: passive.descriptions,
              addTooltip: false,
            ),
          CustomDivider.zeroIndent(color: color, drawShape: false),
        ],
      ),
    );
  }
}

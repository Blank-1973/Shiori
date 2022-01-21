import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiori/application/bloc.dart';
import 'package:shiori/domain/enums/enums.dart';
import 'package:shiori/domain/extensions/string_extensions.dart';
import 'package:shiori/generated/l10n.dart';
import 'package:shiori/presentation/characters/characters_page.dart';
import 'package:shiori/presentation/shared/bullet_list.dart';
import 'package:shiori/presentation/shared/character_stack_image.dart';
import 'package:shiori/presentation/shared/dialogs/select_character_skill_type_dialog.dart';
import 'package:shiori/presentation/shared/dialogs/text_dialog.dart';
import 'package:shiori/presentation/shared/dropdown_button_with_title.dart';
import 'package:shiori/presentation/shared/extensions/element_type_extensions.dart';
import 'package:shiori/presentation/shared/extensions/i18n_extensions.dart';
import 'package:shiori/presentation/shared/loading.dart';
import 'package:shiori/presentation/shared/styles.dart';
import 'package:shiori/presentation/shared/utils/enum_utils.dart';

class CharacterSection extends StatelessWidget {
  const CharacterSection({Key? key}) : super(key: key);

  //TODO: FIGURE OUT A WAY TO SHOW THE IMAGE PROPERLY
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    double imgHeight = height * 0.85;
    if (imgHeight > 1000) {
      imgHeight = 1000;
    }
    final flexA = width < 400 ? 55 : 45;
    final flexB = width < 400 ? 45 : 55;
    return BlocBuilder<CustomBuildBloc, CustomBuildState>(
      builder: (context, state) => state.maybeMap(
        loaded: (state) {
          final canAddNotes = state.notes.map((e) => e.note.length).sum < 300 && state.notes.length < CustomBuildBloc.maxNumberOfNotes;
          final canAddSkillPriorities = CustomBuildBloc.validSkillTypes.length == state.skillPriorities.length;
          return Container(
            color: state.character.elementType.getElementColorFromContext(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: flexA,
                  child: CharacterStackImage(
                    name: state.character.name,
                    image: state.character.image,
                    rarity: state.character.stars,
                    height: imgHeight,
                    onTap: () => _openCharacterPage(context, state.character.key),
                  ),
                ),
                Expanded(
                  flex: flexB,
                  child: Padding(
                    padding: Styles.edgeInsetHorizontal5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                state.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.headline5!.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Tooltip(
                              message: s.recommended,
                              child: IconButton(
                                splashRadius: Styles.smallButtonSplashRadius,
                                icon: Icon(state.isRecommended ? Icons.star : Icons.star_border_outlined),
                                onPressed: () => context.read<CustomBuildBloc>().add(
                                      CustomBuildEvent.isRecommendedChanged(newValue: !state.isRecommended),
                                    ),
                              ),
                            ),
                            Tooltip(
                              message: s.edit,
                              child: IconButton(
                                splashRadius: Styles.smallButtonSplashRadius,
                                icon: const Icon(Icons.edit),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => TextDialog.update(
                                    title: s.title,
                                    value: state.title,
                                    maxLength: CustomBuildBloc.maxTitleLength,
                                    onSave: (newTitle) => context.read<CustomBuildBloc>().add(CustomBuildEvent.titleChanged(newValue: newTitle)),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                        DropdownButtonWithTitle<CharacterRoleType>(
                          margin: EdgeInsets.zero,
                          title: s.role,
                          currentValue: state.type,
                          items: EnumUtils.getTranslatedAndSortedEnum<CharacterRoleType>(
                            CharacterRoleType.values.where((el) => el != CharacterRoleType.na).toList(),
                            (val, _) => s.translateCharacterRoleType(val),
                          ),
                          onChanged: (v) => context.read<CustomBuildBloc>().add(CustomBuildEvent.roleChanged(newValue: v)),
                        ),
                        DropdownButtonWithTitle<CharacterRoleSubType>(
                          margin: EdgeInsets.zero,
                          title: s.subType,
                          currentValue: state.subType,
                          items: EnumUtils.getTranslatedAndSortedEnum<CharacterRoleSubType>(
                            CharacterRoleSubType.values,
                            (val, _) => s.translateCharacterRoleSubType(val),
                          ),
                          onChanged: (v) => context.read<CustomBuildBloc>().add(CustomBuildEvent.subRoleChanged(newValue: v)),
                        ),
                        SwitchListTile(
                          activeColor: theme.colorScheme.secondary,
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.showOnCharacterDetail),
                          value: state.showOnCharacterDetail,
                          onChanged: (v) => context.read<CustomBuildBloc>().add(CustomBuildEvent.showOnCharacterDetailChanged(newValue: v)),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.talentPriority,
                                style: theme.textTheme.subtitle1,
                              ),
                            ),
                            IconButton(
                              splashRadius: Styles.smallButtonSplashRadius,
                              icon: const Icon(Icons.add),
                              onPressed: canAddSkillPriorities
                                  ? null
                                  : () => showDialog(
                                        context: context,
                                        builder: (_) => SelectCharacterSkillTypeDialog(
                                          excluded: CustomBuildBloc.excludedSkillTypes,
                                          selectedValues: state.skillPriorities,
                                          onSave: (type) {
                                            if (type == null) {
                                              return;
                                            }

                                            context.read<CustomBuildBloc>().add(CustomBuildEvent.addSkillPriority(type: type));
                                          },
                                        ),
                                      ),
                            ),
                          ],
                        ),
                        BulletList(
                          iconSize: 14,
                          items: state.skillPriorities.map((e) => s.translateCharacterSkillType(e)).toList(),
                          iconResolver: (index) => Text('#${index + 1}', style: theme.textTheme.subtitle2!.copyWith(fontSize: 12)),
                          fontSize: 10,
                          padding: const EdgeInsets.only(right: 16, left: 5, bottom: 5, top: 5),
                          onDelete: (index) => context.read<CustomBuildBloc>().add(CustomBuildEvent.deleteSkillPriority(index: index)),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.notes,
                                style: theme.textTheme.subtitle1,
                              ),
                            ),
                            IconButton(
                              splashRadius: Styles.smallButtonSplashRadius,
                              icon: const Icon(Icons.add),
                              onPressed: !canAddNotes
                                  ? null
                                  : () => showDialog(
                                        context: context,
                                        builder: (_) => TextDialog.create(
                                          title: s.note,
                                          onSave: (note) => context.read<CustomBuildBloc>().add(CustomBuildEvent.addNote(note: note)),
                                          maxLength: CustomBuildBloc.maxNoteLength,
                                        ),
                                      ),
                            ),
                          ],
                        ),
                        BulletList(
                          iconSize: 14,
                          items: state.notes.map((e) => e.note).toList(),
                          fontSize: 10,
                          padding: const EdgeInsets.only(right: 16, left: 5, bottom: 5, top: 5),
                          onDelete: (index) => context.read<CustomBuildBloc>().add(CustomBuildEvent.deleteNote(index: index)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        orElse: () => const Loading(useScaffold: false),
      ),
    );
  }

  Future<void> _openCharacterPage(BuildContext context, String currentCharKey) async {
    final bloc = context.read<CustomBuildBloc>();
    final selectedKey = await CharactersPage.forSelection(context, excludeKeys: [currentCharKey]);
    if (selectedKey.isNullEmptyOrWhitespace) {
      return;
    }

    bloc.add(CustomBuildEvent.characterChanged(newKey: selectedKey!));
  }
}
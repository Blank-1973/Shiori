import 'dart:math';

import 'package:collection/collection.dart';
import 'package:shiori/domain/assets.dart';
import 'package:shiori/domain/enums/enums.dart';
import 'package:shiori/domain/extensions/string_extensions.dart';
import 'package:shiori/domain/models/models.dart';
import 'package:shiori/domain/services/file/character_file_service.dart';
import 'package:shiori/domain/services/file/file_infrastructure.dart';
import 'package:shiori/domain/services/file/translation_file_service.dart';
import 'package:shiori/domain/services/locale_service.dart';
import 'package:shiori/domain/utils/date_utils.dart';

class CharacterFileServiceImpl extends CharacterFileService {
  final LocaleService _localeService;
  final ArtifactFileService _artifacts;
  final MaterialFileService _materials;
  final WeaponFileService _weapons;
  final TranslationFileService _translations;

  late CharactersFile _charactersFile;

  CharacterFileServiceImpl(this._localeService, this._artifacts, this._materials, this._weapons, this._translations);

  @override
  Future<void> init(String assetPath) async {
    final json = await readJson(assetPath);
    _charactersFile = CharactersFile.fromJson(json);
  }

  @override
  List<CharacterCardModel> getCharactersForCard() {
    return _charactersFile.characters.map((e) => _toCharacterForCard(e)).toList();
  }

  @override
  CharacterFileModel getCharacter(String key) {
    return _charactersFile.characters.firstWhere((element) => element.key == key);
  }

  @override
  List<TierListRowModel> getDefaultCharacterTierList(List<int> colors) {
    assert(colors.length == 7);

    final sssTier = _charactersFile.characters
        .where((char) => !char.isComingSoon && char.tier == 'sss')
        .map((char) => ItemCommon(char.key, Assets.getCharacterPath(char.image)))
        .toList();
    final ssTier = _charactersFile.characters
        .where((char) => !char.isComingSoon && char.tier == 'ss')
        .map((char) => ItemCommon(char.key, Assets.getCharacterPath(char.image)))
        .toList();
    final sTier = _charactersFile.characters
        .where((char) => !char.isComingSoon && char.tier == 's')
        .map((char) => ItemCommon(char.key, Assets.getCharacterPath(char.image)))
        .toList();
    final aTier = _charactersFile.characters
        .where((char) => !char.isComingSoon && char.tier == 'a')
        .map((char) => ItemCommon(char.key, Assets.getCharacterPath(char.image)))
        .toList();
    final bTier = _charactersFile.characters
        .where((char) => !char.isComingSoon && char.tier == 'b')
        .map((char) => ItemCommon(char.key, Assets.getCharacterPath(char.image)))
        .toList();
    final cTier = _charactersFile.characters
        .where((char) => !char.isComingSoon && char.tier == 'c')
        .map((char) => ItemCommon(char.key, Assets.getCharacterPath(char.image)))
        .toList();
    final dTier = _charactersFile.characters
        .where((char) => !char.isComingSoon && char.tier == 'd')
        .map((char) => ItemCommon(char.key, Assets.getCharacterPath(char.image)))
        .toList();

    return <TierListRowModel>[
      TierListRowModel.row(tierText: 'SSS', tierColor: colors.first, items: sssTier),
      TierListRowModel.row(tierText: 'SS', tierColor: colors[1], items: ssTier),
      TierListRowModel.row(tierText: 'S', tierColor: colors[2], items: sTier),
      TierListRowModel.row(tierText: 'A', tierColor: colors[3], items: aTier),
      TierListRowModel.row(tierText: 'B', tierColor: colors[4], items: bTier),
      TierListRowModel.row(tierText: 'C', tierColor: colors[5], items: cTier),
      TierListRowModel.row(tierText: 'D', tierColor: colors.last, items: dTier),
    ];
  }

  @override
  List<ItemCommon> getCharacterForItemsUsingWeapon(String key) {
    final weapon = _weapons.getWeapon(key);
    final items = <ItemCommon>[];
    for (final char in _charactersFile.characters.where((el) => !el.isComingSoon)) {
      for (final build in char.builds) {
        final isBeingUsed = build.weaponKeys.contains(weapon.key);
        if (isBeingUsed && !items.any((el) => el.key == char.key)) {
          items.add(ItemCommon(char.key, Assets.getCharacterPath(char.image)));
        }
      }
    }

    return items;
  }

  @override
  List<ItemCommon> getCharacterForItemsUsingArtifact(String key) {
    final artifact = _artifacts.getArtifact(key);
    final items = <ItemCommon>[];
    for (final char in _charactersFile.characters.where((el) => !el.isComingSoon)) {
      for (final build in char.builds) {
        final isBeingUsed = build.artifacts.any((a) => a.oneKey == artifact.key || a.multiples.any((m) => m.key == artifact.key));

        if (isBeingUsed && !items.any((el) => el.key == char.key)) {
          items.add(ItemCommon(char.key, Assets.getCharacterPath(char.image)));
        }
      }
    }

    return items;
  }

  @override
  List<ItemCommon> getCharacterForItemsUsingMaterial(String key) {
    final material = _materials.getMaterial(key);
    final imgs = <ItemCommon>[];

    for (final char in _charactersFile.characters.where((c) => !c.isComingSoon)) {
      final multiTalentAscensionMaterials =
          (char.multiTalentAscensionMaterials?.expand((e) => e.materials).expand((e) => e.materials) ?? <ItemAscensionMaterialFileModel>[]).toList();

      final ascensionMaterial = char.ascensionMaterials.expand((e) => e.materials).toList();
      final talentMaterial = char.talentAscensionMaterials.expand((e) => e.materials).toList();

      final materials = multiTalentAscensionMaterials + ascensionMaterial + talentMaterial;
      final allMaterials = _materials.getMaterialsFromAscensionMaterials(materials);

      if (allMaterials.any((m) => m.key == material.key)) {
        imgs.add(ItemCommon(char.key, Assets.getCharacterPath(char.image)));
      }
    }

    return imgs;
  }

  @override
  List<TodayCharAscensionMaterialsModel> getCharacterAscensionMaterials(int day) {
    return _materials.getCharacterAscensionMaterials(day).map((e) {
      final translation = _translations.getMaterialTranslation(e.key);
      final characters = <ItemCommon>[];

      for (final char in _charactersFile.characters) {
        if (char.isComingSoon) {
          continue;
        }
        final normalAscMaterial = char.ascensionMaterials.expand((m) => m.materials).where((m) => m.key == e.key).isNotEmpty ||
            char.talentAscensionMaterials.expand((m) => m.materials).where((m) => m.key == e.key).isNotEmpty;

        //The travelers have different ascension materials, that's why we do the following
        var specialAscMaterial = false;
        if (char.multiTalentAscensionMaterials != null) {
          final keyword = e.key;
          final materials = char.multiTalentAscensionMaterials!
              .expand((m) => m.materials)
              .expand((m) => m.materials)
              .where((m) => m.type == MaterialType.talents)
              .map((e) => e.key)
              .toSet()
              .toList();

          specialAscMaterial = materials.any((m) => m == keyword);
        }

        final materialIsBeingUsed = normalAscMaterial || specialAscMaterial;
        if (materialIsBeingUsed && !characters.any((el) => el.key == char.key)) {
          characters.add(ItemCommon(char.key, Assets.getCharacterPath(char.image)));
        }
      }

      return e.isFromBoss
          ? TodayCharAscensionMaterialsModel.fromBoss(
              key: e.key,
              name: translation.name,
              image: Assets.getMaterialPath(e.image, e.type),
              bossName: translation.bossName,
              characters: characters,
            )
          : TodayCharAscensionMaterialsModel.fromDays(
              key: e.key,
              name: translation.name,
              image: Assets.getMaterialPath(e.image, e.type),
              characters: characters,
              days: e.days,
            );
    }).toList();
  }

  @override
  CharacterCardModel getCharacterForCard(String key) {
    final character = _charactersFile.characters.firstWhere((el) => el.key == key);
    return _toCharacterForCard(character);
  }

  @override
  List<ChartBirthdayMonthModel> getCharacterBirthdaysForCharts() {
    final grouped = _charactersFile.characters
        .where((char) => !char.isComingSoon && !char.birthday.isNullEmptyOrWhitespace)
        .groupListsBy((char) => _localeService.getCharBirthDate(char.birthday).month)
        .entries;

    final birthdays = grouped
        .map(
          (e) => ChartBirthdayMonthModel(
            month: e.key,
            items: e.value.map((e) {
              final translation = _translations.getCharacterTranslation(e.key);
              return ItemCommonWithName(e.key, e.fullImagePath, translation.name);
            }).toList(),
          ),
        )
        .toList()
      ..sort((x, y) => x.month.compareTo(y.month));

    assert(birthdays.length == 12, 'Birthday items for chart should not be empty and must be equal to 12');

    return birthdays;
  }

  @override
  List<ChartCharacterRegionModel> getCharacterRegionsForCharts() {
    return RegionType.values.where((el) => el != RegionType.anotherWorld).map((type) {
      final quantity = _charactersFile.characters.where((el) => !el.isComingSoon && el.region == type).length;
      return ChartCharacterRegionModel(regionType: type, quantity: quantity);
    }).toList()
      ..sort((x, y) => y.quantity.compareTo(x.quantity));
  }

  @override
  ChartGenderModel getCharacterGendersByRegionForCharts(RegionType regionType) {
    if (regionType == RegionType.anotherWorld) {
      throw Exception('Another world is not supported');
    }

    final characters = _charactersFile.characters.where((el) => !el.isComingSoon && el.region == regionType).toList();
    final maleCount = characters.where((el) => !el.isFemale).length;
    final femaleCount = characters.where((el) => el.isFemale).length;
    return ChartGenderModel(regionType: regionType, maleCount: maleCount, femaleCount: femaleCount, maxCount: max(maleCount, femaleCount));
  }

  @override
  List<ItemCommonWithName> getCharactersForItemsByRegion(RegionType regionType) {
    if (regionType == RegionType.anotherWorld) {
      throw Exception('Another world is not supported');
    }

    return _charactersFile.characters.where((el) => !el.isComingSoon && el.region == regionType).map((e) {
      final char = getCharacterForCard(e.key);
      return ItemCommonWithName(e.key, char.image, char.name);
    }).toList()
      ..sort((x, y) => x.name.compareTo(y.name));
  }

  @override
  List<ItemCommonWithName> getCharactersForItemsByRegionAndGender(RegionType regionType, bool onlyFemales) {
    if (regionType == RegionType.anotherWorld) {
      throw Exception('Another world is not supported');
    }

    return _charactersFile.characters.where((el) => !el.isComingSoon && el.region == regionType && el.isFemale == onlyFemales).map((e) {
      final char = getCharacterForCard(e.key);
      return ItemCommonWithName(e.key, char.image, char.name);
    }).toList()
      ..sort((x, y) => x.name.compareTo(y.name));
  }

  @override
  List<CharacterBirthdayModel> getCharacterBirthdays({int? month, int? day}) {
    if (month == null && day == null) {
      throw Exception('You must provide a month, day or both');
    }

    if (month != null && (month < DateTime.january || month > DateTime.december)) {
      throw Exception('The provided month = $month is not valid');
    }

    if (day != null && day <= 0) {
      throw Exception('The provided day = $day is not valid');
    }

    if (day != null && month != null) {
      final lastDay = DateUtils.getLastDayOfMonth(month);
      if (day > lastDay) {
        throw Exception('The provided day = $day is not valid for month = $month');
      }
    }

    return _charactersFile.characters.where((char) {
      if (char.isComingSoon) {
        return false;
      }

      if (char.birthday.isNullEmptyOrWhitespace) {
        return false;
      }

      final charBirthday = _localeService.getCharBirthDate(char.birthday);
      if (month != null && day != null) {
        return charBirthday.month == month && charBirthday.day == day;
      }
      if (month != null) {
        return charBirthday.month == month;
      }
      if (day != null) {
        return charBirthday.day == day;
      }

      return true;
    }).map((e) {
      final char = getCharacterForCard(e.key);
      final birthday = _localeService.getCharBirthDate(e.birthday, useCurrentYear: true);
      final now = DateTime.now();
      final nowFromZero = DateTime(now.year, now.month, now.day);
      return CharacterBirthdayModel(
        key: e.key,
        name: char.name,
        image: char.image,
        birthday: birthday,
        birthdayString: e.birthday!,
        daysUntilBirthday: nowFromZero.difference(birthday).inDays.abs(),
      );
    }).toList()
      ..sort((x, y) => x.daysUntilBirthday.compareTo(y.daysUntilBirthday));
  }

  @override
  List<String> getUpcomingCharactersKeys() => _charactersFile.characters.where((el) => el.isComingSoon).map((e) => e.key).toList();

  @override
  List<CharacterSkillStatModel> getCharacterSkillStats(List<CharacterFileSkillStatModel> skillStats, List<String> statsTranslations) {
    final stats = <CharacterSkillStatModel>[];
    if (skillStats.isEmpty || statsTranslations.isEmpty) {
      return stats;
    }
    final statExp = RegExp('(?<={).+?(?=})');
    final maxLevel = skillStats.first.values.length;
    for (var i = 1; i <= maxLevel; i++) {
      final stat = CharacterSkillStatModel(level: i, descriptions: []);
      for (final translation in statsTranslations) {
        // "Curación continua|{param3}% Max HP + {param4}",
        final splitted = translation.split('|');
        if (splitted.isEmpty || splitted.length != 2) {
          continue;
        }
        final desc = splitted.first;
        var toReplace = splitted[1];
        final matches = statExp.allMatches(toReplace);
        for (final match in matches) {
          final val = match.group(0);
          final statValues = skillStats.firstWhereOrNull((el) => el.key == val);
          if (statValues == null) {
            continue;
          }

          if (statValues.values.length - 1 < i - 1) {
            continue;
          }

          final statValue = statValues.values[i - 1];
          toReplace = toReplace.replaceFirst('{$val}', '$statValue');
        }

        stat.descriptions.add('$desc|$toReplace');
      }

      stats.add(stat);
    }

    return stats;
  }

  @override
  List<ChartGenderModel> getCharacterGendersForCharts() =>
      RegionType.values.where((el) => el != RegionType.anotherWorld).map((e) => getCharacterGendersByRegionForCharts(e)).toList()
        ..sort((x, y) => y.maxCount.compareTo(x.maxCount));

  @override
  int countByStatType(StatType statType) {
    return _charactersFile.characters.where((el) => !el.isComingSoon && el.subStatType == statType).length;
  }

  @override
  List<ItemCommonWithName> getItemCommonWithNameByRarity(int rarity) {
    return getCharactersForCard().where((el) => el.stars == rarity).map((e) => ItemCommonWithName(e.key, e.image, e.name)).toList();
  }

  @override
  List<ItemCommonWithName> getItemCommonWithNameByStatType(StatType statType) {
    return _charactersFile.characters.where((el) => el.subStatType == statType && !el.isComingSoon).map((e) {
      final translation = _translations.getCharacterTranslation(e.key);
      return ItemCommonWithName(e.key, e.fullImagePath, translation.name);
    }).toList();
  }

  CharacterCardModel _toCharacterForCard(CharacterFileModel character) {
    final translation = _translations.getCharacterTranslation(character.key);

    //The reduce is to take the material with the biggest level of each type
    final multiTalentAscensionMaterials = character.multiTalentAscensionMaterials ?? <CharacterFileMultiTalentAscensionMaterialModel>[];

    final ascensionMaterial = character.ascensionMaterials.isNotEmpty
        ? character.ascensionMaterials.reduce((current, next) => current.level > next.level ? current : next)
        : null;

    final talentMaterial = character.talentAscensionMaterials.isNotEmpty
        ? character.talentAscensionMaterials.reduce((current, next) => current.level > next.level ? current : next)
        : multiTalentAscensionMaterials.isNotEmpty
            ? multiTalentAscensionMaterials.expand((e) => e.materials).reduce((current, next) => current.level > next.level ? current : next)
            : null;

    final materials =
        (ascensionMaterial?.materials ?? <ItemAscensionMaterialFileModel>[]) + (talentMaterial?.materials ?? <ItemAscensionMaterialFileModel>[]);

    final quickMaterials = _materials.getMaterialsFromAscensionMaterials(materials);

    return CharacterCardModel(
      key: character.key,
      elementType: character.elementType,
      image: Assets.getCharacterPath(character.image),
      materials: quickMaterials.map((m) => m.fullImagePath).toList(),
      name: translation.name,
      stars: character.rarity,
      weaponType: character.weaponType,
      isComingSoon: character.isComingSoon,
      isNew: character.isNew,
      roleType: character.role,
      regionType: character.region,
      subStatType: character.subStatType,
    );
  }
}

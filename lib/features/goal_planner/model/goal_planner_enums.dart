enum UserRole { parent, child }

enum TabungType {
  electronicDevice,
  food,
  personalGrowth,
  sportArt,
  travel,
}

enum RecurringPeriod { daily, weekly, monthly }

enum DifficultyLevel { easy, medium, hard }

extension EnumValue on Enum {
  String wireValue() => switch (this) {
        UserRole.parent => 'parent',
        UserRole.child => 'child',
        TabungType.electronicDevice => 'electronic device',
        TabungType.food => 'food',
        TabungType.personalGrowth => 'growth fund',
        TabungType.sportArt => 'sport and art',
        TabungType.travel => 'travel',
        RecurringPeriod.daily => 'daily',
        RecurringPeriod.weekly => 'weekly',
        RecurringPeriod.monthly => 'monthly',
        DifficultyLevel.easy => 'easy',
        DifficultyLevel.medium => 'medium',
        DifficultyLevel.hard => 'hard',
        _ => name,
      };
}

extension GoalPlannerApiWires on UserRole {
  String apiWireValue() => switch (this) {
        UserRole.parent => 'parent',
        UserRole.child => 'child',
      };
}

extension TabungTypeWireValues on TabungType {
  String apiWireValue() => switch (this) {
        TabungType.electronicDevice => 'electronic device',
        TabungType.food => 'food',
        TabungType.personalGrowth => 'growth fund',
        TabungType.sportArt => 'sport and art',
        TabungType.travel => 'travel',
      };

  String dbWireValue() => switch (this) {
        TabungType.electronicDevice => 'gadget',
        TabungType.food => 'custom',
        TabungType.personalGrowth => 'education',
        TabungType.sportArt => 'custom',
        TabungType.travel => 'travel',
      };
}

extension TabungTypeUi on TabungType {
  String get title => switch (this) {
        TabungType.electronicDevice => 'Electronic Device Tabung',
        TabungType.food => 'Food Tabung',
        TabungType.personalGrowth => 'Personal Growth Tabung',
        TabungType.sportArt => 'Sport & Art Tabung',
        TabungType.travel => 'Travel Tabung',
      };

  String get shortLabel => switch (this) {
        TabungType.electronicDevice => 'Electronic Device',
        TabungType.food => 'Food',
        TabungType.personalGrowth => 'Personal Growth',
        TabungType.sportArt => 'Sport & Art',
        TabungType.travel => 'Travel',
      };

  String get assetPath => switch (this) {
        TabungType.electronicDevice => 'assets/images/tabung/electronicdevice_jar.png',
        TabungType.food => 'assets/images/tabung/food_jar.png',
        TabungType.personalGrowth => 'assets/images/tabung/personal_growth_jar.png',
        TabungType.sportArt => 'assets/images/tabung/sport_art_jar.png',
        TabungType.travel => 'assets/images/tabung/travel_jar.png',
      };

  ColorToken get colorToken => switch (this) {
        TabungType.electronicDevice => const ColorToken(0xFF7A9B98, 0xFF31B7A3),
        TabungType.food => const ColorToken(0xFF9A8C6A, 0xFFCCB06A),
        TabungType.personalGrowth => const ColorToken(0xFF87A987, 0xFF5BC07C),
        TabungType.sportArt => const ColorToken(0xFF8B8883, 0xFFCFA66A),
        TabungType.travel => const ColorToken(0xFF739997, 0xFF3CB7A8),
      };
}

class ColorToken {
  const ColorToken(this.cardColorHex, this.buttonColorHex);

  final int cardColorHex;
  final int buttonColorHex;
}

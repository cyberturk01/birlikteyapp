import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

class AppLists {
  static List<String> defaultTasks(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return [
      t.taskTakeOutTrash,
      t.taskCleanKitchen,
      t.taskDoLaundry,
      t.taskVacuumLiving,
      t.taskWashDishes,
      t.taskWaterPlants,
      t.taskCookDinner,
      t.taskOrganizeFridge,
      t.taskChangeBedsheets,
      t.taskIronClothes,
    ];
  }

  static List<String> defaultItems(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return [
      t.itemMilk,
      t.itemBread,
      t.itemEggs,
      t.itemButter,
      t.itemCheese,
      t.itemRice,
      t.itemPasta,
      t.itemTomatoes,
      t.itemPotatoes,
      t.itemOnions,
      t.itemApples,
      t.itemBananas,
      t.itemChicken,
      t.itemBeef,
      t.itemFish,
      t.itemOliveOil,
      t.itemSalt,
      t.itemSugar,
      t.itemCoffee,
      t.itemTea,
    ];
  }
}

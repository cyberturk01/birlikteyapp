// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Togetherly';

  @override
  String get welcome => 'Willkommen';

  @override
  String get tasks => 'Aufgaben';

  @override
  String get items => 'Artikel';

  @override
  String get expenses => 'Ausgaben';

  @override
  String get weekly => 'Wöchentlich';

  @override
  String get members => 'Mitglieder';

  @override
  String get leaderboard => 'Bestenliste';

  @override
  String get signOut => 'Abmelden';

  @override
  String get welcomeBack => 'Willkommen zurück';

  @override
  String get addMember => 'Mitglied hinzufügen';

  @override
  String get pickMember => 'Wählen Sie ein Mitglied, um fortzufahren';

  @override
  String get searchMember => 'Mitglied suchen…';

  @override
  String get noMembersFound => 'Keine Mitglieder gefunden';

  @override
  String seeAllMembers(Object count) {
    return 'Alle Mitglieder anzeigen ($count)';
  }

  @override
  String get goToDashboard => 'Zum Dashboard';

  @override
  String get setupFamily => 'Lassen Sie uns Ihre Familie einrichten';

  @override
  String get setupFamilyDesc => 'Fügen Sie Ihr erstes Familienmitglied hinzu, um Aufgaben und Einkaufslisten gemeinsam zu nutzen.';

  @override
  String get addFirstMember => 'Erstes Mitglied hinzufügen';

  @override
  String get setupFamilyHint => 'Sie können jederzeit oben rechts weitere Mitglieder hinzufügen.';

  @override
  String get allMembers => 'Alle Mitglieder';

  @override
  String get showLess => 'Weniger anzeigen';

  @override
  String get showAll => 'Alle anzeigen';

  @override
  String showAllCount(int count) {
    return 'Alle anzeigen ($count)';
  }

  @override
  String get category => 'Kategorie';

  @override
  String get price => 'Preis';

  @override
  String get itemBoughtToast => '🎉 Artikel gekauft!';

  @override
  String get configTitle => 'Konfiguration';

  @override
  String get configSubtitle => 'Theme, Erinnerungen und Familienfilter anpassen.';

  @override
  String get familyInviteCode => 'Familieneinladungscode';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get language => 'Sprache';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get appColor => 'App-Farbe';

  @override
  String get templates => 'Vorlagen';

  @override
  String get templatesSubtitle => 'Ein-Tipp Aufgaben- & Einkaufspakete';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get requestPermission => 'Berechtigung anfordern';

  @override
  String get permissionRequested => 'Berechtigung angefordert (falls nötig)';

  @override
  String get preciseAlarmsTooltip => 'Systemeinstellung für präzise Alarme öffnen';

  @override
  String get androidOnly => 'Diese Einstellung ist nur für Android';

  @override
  String get enableExactAlarms => 'Präzise Alarme aktivieren';

  @override
  String get couldNotOpenSettings => 'Einstellungen konnten nicht geöffnet werden';

  @override
  String get menuManageFamily => 'Familie verwalten';

  @override
  String get menuAddCenter => 'Hinzufügen Zentrum';

  @override
  String get dismiss => 'SCHLIESSEN';

  @override
  String get market => 'Einkauf';

  @override
  String get pendingToday => 'Heute fällig';

  @override
  String get toBuy => 'Zu kaufen';

  @override
  String get totalRecords => 'Gesamtanzahl';

  @override
  String get pendingTasks => 'Offene Aufgaben';

  @override
  String get myTasks => 'Meine Aufgaben';

  @override
  String get unassigned => 'Ohne Zuordnung';

  @override
  String get itemsHeader => 'Artikel';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get editTask => 'Aufgabe bearbeiten';

  @override
  String get taskName => 'Aufgabenname';

  @override
  String get editItem => 'Artikel bearbeiten';

  @override
  String get itemName => 'Artikelname';

  @override
  String get mine => 'Meine';

  @override
  String get noData => 'Keine Daten';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get assignTask => 'Aufgabe zuweisen';

  @override
  String get assignItem => 'Artikel zuweisen';

  @override
  String get assignTo => 'Zuweisen an';

  @override
  String get noOne => 'Niemand';

  @override
  String get searchTasks => 'Aufgaben suchen…';

  @override
  String get searchItems => 'Artikel suchen…';

  @override
  String get filterByAssignee => 'Nach Zuständigem filtern';

  @override
  String get pendingLabel => 'Offen';

  @override
  String get allLabel => 'Alle';

  @override
  String get noTasks => 'Keine Aufgaben';

  @override
  String get clearCompleted => 'Erledigte löschen';

  @override
  String get completedTasksCleared => 'Erledigte Aufgaben gelöscht';

  @override
  String get markAllDone => 'Alle erledigen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get assign => 'Zuweisen';

  @override
  String get delete => 'Löschen';

  @override
  String get editDueReminder => 'Bearbeiten (Fälligkeit/Erinnerung)';

  @override
  String get noItems => 'Keine Artikel';

  @override
  String get clearBought => 'Gekaufte löschen';

  @override
  String get boughtItemsCleared => 'Gekaufte Artikel gelöscht';

  @override
  String get markAllBought => 'Als Erledigt';

  @override
  String get memberFallback => 'Mitglied';

  @override
  String pendingCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Offen ($count)',
      one: 'Offen (1)',
      zero: 'Offen',
    );
    return '$_temp0';
  }

  @override
  String completedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Erledigt ($count)',
      one: 'Erledigt (1)',
      zero: 'Erledigt',
    );
    return '$_temp0';
  }

  @override
  String toBuyCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zu kaufen ($count)',
      one: 'Zu kaufen (1)',
      zero: 'Zu kaufen',
    );
    return '$_temp0';
  }

  @override
  String boughtCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gekauft ($count)',
      one: 'Gekauft (1)',
      zero: 'Gekauft',
    );
    return '$_temp0';
  }

  @override
  String get completedLabel => 'Erledigt';

  @override
  String get boughtLabel => 'Gekauft';

  @override
  String get addTaskBtn => 'Aufgabe hinzufügen';

  @override
  String get addItemBtn => 'Artikel hinzufügen';

  @override
  String addTaskFor(String name) {
    return 'Aufgabe für $name hinzufügen';
  }

  @override
  String addItemFor(String name) {
    return 'Artikel für $name hinzufügen';
  }

  @override
  String get enterTasksHint => 'Aufgaben eingeben (Komma oder neue Zeile)…';

  @override
  String get tasksHelperExample => 'Beispiel: Wäsche, Abwasch, Müll rausbringen';

  @override
  String get enterItemsHint => 'Artikel eingeben (Komma oder neue Zeile)…';

  @override
  String get itemsHelperExample => 'Beispiel: Milch, Brot, Eier';

  @override
  String get suggestionsTitle => 'Vorschläge';

  @override
  String get addTypedList => 'Hinzufügen';

  @override
  String get itemDeleted => 'Artikel gelöscht';

  @override
  String get addSelected => 'Auswahl hinzufügen';

  @override
  String addSelectedCount(int count) {
    return 'Auswahl hinzufügen ($count)';
  }

  @override
  String addedTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufgaben hinzugefügt',
      one: '1 Aufgabe hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String addedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Artikel hinzugefügt',
      one: '1 Artikel hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String get clearedUndo => 'Gelöscht – Rückgängig';

  @override
  String get undo => 'Rückgängig';

  @override
  String get setDueDate => 'Fälligkeit wählen';

  @override
  String get setReminder => 'Erinnerung einstellen';

  @override
  String get clear => 'Leeren';

  @override
  String duePrefix(String date) {
    return 'Fällig: $date';
  }

  @override
  String remindPrefix(String date) {
    return 'Erinnern: $date';
  }

  @override
  String get taskDeleted => 'Aufgabe gelöscht';

  @override
  String get more => 'Mehr';

  @override
  String get taskCompletedToast => '🎉 Aufgabe erledigt!';

  @override
  String pointsAwarded(int points) {
    return '➕ +$points Punkte';
  }

  @override
  String get thisMonth => 'Diesen Monat';

  @override
  String get lastMonth => 'Letzten Monat';

  @override
  String get noExpenses => 'Keine Ausgaben';

  @override
  String get deleteExpenseTitle => 'Ausgabe löschen?';

  @override
  String deleteExpenseBody(String title) {
    return '„$title“ wird entfernt. Du kannst es direkt danach rückgängig machen.';
  }

  @override
  String get expenseDeleted => 'Ausgabe gelöscht';

  @override
  String deleteFailed(String error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String get addExpense => 'Ausgabe hinzufügen';

  @override
  String get insights => 'Einblicke';

  @override
  String get otherCategory => 'Sonstiges';

  @override
  String expensesInsightsTitleHint(Object expenses, Object insights) {
    return 'Compose with: $expenses — $insights';
  }

  @override
  String get memberLabel => 'Mitglied';

  @override
  String get byCategory => 'Nach Kategorie';

  @override
  String get export => 'Exportieren';

  @override
  String get share => 'Teilen';

  @override
  String get transactions => 'Buchungen';

  @override
  String recordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
    );
    return '$_temp0';
  }

  @override
  String get exportCsvTooltip => 'CSV exportieren';

  @override
  String get shareTooltip => 'Teilen';

  @override
  String get noExpensesForRange => 'Keine Ausgaben für den ausgewählten Zeitraum.';

  @override
  String savedCsvWithName(String name) {
    return 'CSV gespeichert: $name';
  }

  @override
  String exportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String shareFailed(String error) {
    return 'Teilen fehlgeschlagen: $error';
  }

  @override
  String get changeCategory => 'Kategorie ändern';

  @override
  String get uncategorized => 'Ohne Kategorie';

  @override
  String get customCategory => 'Eigene Kategorie';

  @override
  String get csvDate => 'datum';

  @override
  String get csvTitle => 'titel';

  @override
  String get csvAmount => 'betrag';

  @override
  String get csvMember => 'mitglied';

  @override
  String get csvCategory => 'kategorie';

  @override
  String get expensesCsvShareText => 'Togetherly — Ausgaben CSV';

  @override
  String get categoryGroceries => 'Lebensmittel';

  @override
  String get categoryDining => 'Essen gehen';

  @override
  String get categoryClothing => 'Kleidung';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryUtilities => 'Nebenkosten';

  @override
  String get categoryHealth => 'Gesundheit';

  @override
  String get categoryKids => 'Kinder';

  @override
  String get categoryHome => 'Zuhause';

  @override
  String get categoryOther => 'Sonstiges';

  @override
  String get monthShortJan => 'J';

  @override
  String get monthShortFeb => 'F';

  @override
  String get monthShortMar => 'M';

  @override
  String get monthShortApr => 'A';

  @override
  String get monthShortMay => 'M';

  @override
  String get monthShortJun => 'J';

  @override
  String get monthShortJul => 'J';

  @override
  String get monthShortAug => 'A';

  @override
  String get monthShortSep => 'S';

  @override
  String get monthShortOct => 'O';

  @override
  String get monthShortNov => 'N';

  @override
  String get monthShortDec => 'D';

  @override
  String get expensesByCategoryTitle => 'Ausgaben — nach Kategorie';

  @override
  String get breakdown => 'Aufschlüsselung';

  @override
  String get trend => 'Trend';

  @override
  String get member => 'Mitglied';

  @override
  String get totalsByCategory => 'Summen nach Kategorie';

  @override
  String get editBudgetTooltip => 'Budget bearbeiten';

  @override
  String budgetDialogTitle(String category) {
    return 'Budget — $category';
  }

  @override
  String get monthlyBudgetLabel => 'Monatliches Budget';

  @override
  String get monthlyBudgetHint => 'z. B. 250';

  @override
  String get remove => 'Entfernen';

  @override
  String budgetUpdatedFor(String category) {
    return 'Budget für $category aktualisiert';
  }

  @override
  String get last6MonthsByCategory => 'Letzte 6 Monate nach Kategorie';

  @override
  String get noDataLastMonths => 'Keine Daten für die letzten Monate.';

  @override
  String categoryTitle(String category) {
    return 'Kategorie — $category';
  }

  @override
  String get budgetsMenu => 'Budgets…';

  @override
  String inviteCodeCopied(String code) {
    return 'Einladungscode kopiert: $code';
  }

  @override
  String get ownerLabel => 'Eigentümer';

  @override
  String get editMember => 'Mitglied bearbeiten';

  @override
  String get changePhoto => 'Foto ändern';

  @override
  String get removePhoto => 'Foto entfernen';

  @override
  String get removeUser => 'Mitglied entfernen';

  @override
  String photoUpdateFailed(String error) {
    return 'Foto konnte nicht aktualisiert werden: $error';
  }

  @override
  String removeFailed(String error) {
    return 'Entfernen fehlgeschlagen: $error';
  }

  @override
  String get memberRemoved => 'Mitglied entfernt';

  @override
  String get removeMemberTitle => 'Mitglied entfernen?';

  @override
  String removeMemberBody(String name) {
    return '„$name“ wird aus dieser Familie entfernt.';
  }

  @override
  String get inviteMember => 'Mitglied einladen';

  @override
  String get shareInviteCode => 'Einladungscode deiner Familie teilen';

  @override
  String get copyCode => 'Code kopieren';

  @override
  String get copyAndShare => 'Kopieren & Teilen';

  @override
  String get inviteCode => 'Einladungscode';

  @override
  String get noFamilyMembersYet => 'Noch keine Familienmitglieder';

  @override
  String get useInviteCodeHint => 'Verwende den obigen Einladungscode, um Mitglieder hinzuzufügen.';

  @override
  String get editMemberLabel => 'Mitgliedsbezeichnung bearbeiten';

  @override
  String get label => 'Bezeichnung';

  @override
  String get setupYourFamily => 'Richte deine Familie ein';

  @override
  String get createFamilyTab => 'Familie erstellen';

  @override
  String get joinWithCodeTab => 'Mit Code beitreten';

  @override
  String get chooseFamilyName => 'Wähle einen Familiennamen';

  @override
  String get familyNameLabel => 'Familienname';

  @override
  String get familyNameHint => 'z. B. Familie Müller';

  @override
  String get nameCheckingOk => 'Super! Dieser Name ist verfügbar.';

  @override
  String get nameCheckingTaken => 'Dieser Name ist bereits vergeben. Versuche eine dieser Optionen:';

  @override
  String get createFamilyCta => 'Familie erstellen';

  @override
  String get joinExistingFamily => 'Einer bestehenden Familie beitreten';

  @override
  String get inviteCodeLabel => 'Einladungscode';

  @override
  String get inviteCodeHint => 'z. B. ABCD23';

  @override
  String get paste => 'Einfügen';

  @override
  String get joinFamilyCta => 'Familie beitreten';

  @override
  String get errorFamilyNameEmpty => 'Der Familienname darf nicht leer sein';

  @override
  String get errorNameUnavailable => 'Dieser Name ist derzeit nicht verfügbar';

  @override
  String get errorInviteEmpty => 'Der Einladungscode darf nicht leer sein';

  @override
  String get errorInviteInvalid => 'Ungültiger Einladungscode';

  @override
  String get inviteYourFamily => 'Lade deine Familie ein';

  @override
  String get inviteShareHelp => 'Teile diesen Code mit deiner Familie, um deinem Haushalt beizutreten.';

  @override
  String get copy => 'Kopieren';

  @override
  String get done => 'Fertig';

  @override
  String inviteShareText(String code) {
    return 'Tritt unserer Familie bei Togetherly bei: $code';
  }

  @override
  String get weeklyTaskPlanTitle => 'Wöchentlicher Aufgabenplan';

  @override
  String get weeklyTaskPlanSubtitle => 'Plane wöchentliche Routinen und weise sie deiner Familie zu.';

  @override
  String get defaultTime => 'Standardzeit';

  @override
  String addToDayShort(String day) {
    return 'Zu $day hinzufügen';
  }

  @override
  String get noWeeklyTasks => 'Noch keine Aufgaben';

  @override
  String addTaskForDay(String day) {
    return 'Aufgabe für $day hinzufügen';
  }

  @override
  String get enterTaskHint => 'Aufgabe eingeben…';

  @override
  String get assignToOptional => 'Zuweisen an (optional)';

  @override
  String addedToDay(String day) {
    return 'Zu $day hinzugefügt';
  }

  @override
  String addedToDayAndSynced(String day) {
    return 'Zu $day hinzugefügt und mit Aufgaben synchronisiert';
  }

  @override
  String get defaultWeeklyReminderSaved => 'Standardzeit für wöchentliche Erinnerung gespeichert';

  @override
  String get onLabel => 'Ein';

  @override
  String get offLabel => 'Aus';

  @override
  String get disableNotifications => 'Benachrichtigungen deaktivieren';

  @override
  String get enableNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get notificationsEnabled => 'Benachrichtigungen aktiviert';

  @override
  String get notificationsDisabled => 'Benachrichtigungen deaktiviert';

  @override
  String get setTime => 'Zeit einstellen';

  @override
  String get clearTime => 'Zeit löschen';

  @override
  String get reminderUpdated => 'Erinnerung aktualisiert';

  @override
  String get reminderTimeCleared => 'Erinnerungszeit gelöscht';

  @override
  String get editWeeklyTask => 'Wöchentliche Aufgabe bearbeiten';

  @override
  String get dayLabel => 'Tag';

  @override
  String get assignToLabel => 'Zuweisen an';

  @override
  String get reminderTime => 'Erinnerungszeit';

  @override
  String get notSet => 'Nicht festgelegt';

  @override
  String get notificationsLabel => 'Benachrichtigungen';

  @override
  String get weeklyTaskUpdated => 'Wöchentliche Aufgabe aktualisiert';

  @override
  String get weekdayShortMon => 'Mo';

  @override
  String get weekdayShortTue => 'Di';

  @override
  String get weekdayShortWed => 'Mi';

  @override
  String get weekdayShortThu => 'Do';

  @override
  String get weekdayShortFri => 'Fr';

  @override
  String get weekdayShortSat => 'Sa';

  @override
  String get weekdayShortSun => 'So';

  @override
  String get weekdayMonday => 'Montag';

  @override
  String get weekdayTuesday => 'Dienstag';

  @override
  String get weekdayWednesday => 'Mittwoch';

  @override
  String get weekdayThursday => 'Donnerstag';

  @override
  String get weekdayFriday => 'Freitag';

  @override
  String get weekdaySaturday => 'Samstag';

  @override
  String get weekdaySunday => 'Sonntag';

  @override
  String get editExpense => 'Ausgabe bearbeiten';

  @override
  String get titleLabel => 'Titel';

  @override
  String get amountLabel => 'Betrag';

  @override
  String get newCategory => 'Neue Kategorie';

  @override
  String get nameLabel => 'Name';

  @override
  String get recentLabel => 'Zuletzt verwendet';

  @override
  String get titleRequired => 'Titel ist erforderlich';

  @override
  String get enterValidAmount => 'Bitte einen gültigen Betrag eingeben';

  @override
  String get amountGreaterThanZero => 'Betrag muss größer als 0 sein';

  @override
  String addedAmount(String amount) {
    return '$amount hinzugefügt';
  }

  @override
  String updatedAmount(String amount) {
    return '$amount aktualisiert';
  }

  @override
  String saveFailedWithError(String error) {
    return 'Fehler beim Speichern: $error';
  }

  @override
  String get noActiveFamily => 'Keine aktive Familie';

  @override
  String get add => 'Hinzufügen';

  @override
  String get week => 'Woche';

  @override
  String get today => 'Heute';

  @override
  String get month => 'Monat';

  @override
  String get quickAddTitle => 'Schnell hinzufügen';

  @override
  String get quickAddSubtitle => 'Neue Aufgaben und Einkaufsartikel an einem Ort hinzufügen.';

  @override
  String get allTasksHeader => 'Alle Aufgaben';

  @override
  String get allItemsHeader => 'Alle Artikel';

  @override
  String get enterTaskHintShort => 'Aufgabe eingeben…';

  @override
  String get enterItemHintShort => 'Artikel eingeben…';

  @override
  String get taskAlreadyExists => 'Diese Aufgabe ist bereits vorhanden';

  @override
  String get itemAlreadyExists => 'Dieser Artikel ist bereits vorhanden';

  @override
  String get taskAddedToast => 'Aufgabe hinzugefügt';

  @override
  String get itemAddedToast => 'Artikel hinzugefügt';

  @override
  String get editNameTitle => 'Name bearbeiten';

  @override
  String get assignTooltip => 'Zuweisen';

  @override
  String get editTooltip => 'Bearbeiten';

  @override
  String get taskTakeOutTrash => 'Den Müll rausbringen';

  @override
  String get taskCleanKitchen => 'Die Küche putzen';

  @override
  String get taskDoLaundry => 'Wäsche waschen';

  @override
  String get taskVacuumLiving => 'Wohnzimmer staubsaugen';

  @override
  String get taskWashDishes => 'Geschirr spülen';

  @override
  String get taskWaterPlants => 'Pflanzen gießen';

  @override
  String get taskCookDinner => 'Abendessen kochen';

  @override
  String get taskOrganizeFridge => 'Kühlschrank ordnen';

  @override
  String get taskChangeBedsheets => 'Bettwäsche wechseln';

  @override
  String get taskIronClothes => 'Kleidung bügeln';

  @override
  String get itemMilk => 'Milch';

  @override
  String get itemBread => 'Brot';

  @override
  String get itemEggs => 'Eier';

  @override
  String get itemButter => 'Butter';

  @override
  String get itemCheese => 'Käse';

  @override
  String get itemRice => 'Reis';

  @override
  String get itemPasta => 'Pasta';

  @override
  String get itemTomatoes => 'Tomaten';

  @override
  String get itemPotatoes => 'Kartoffeln';

  @override
  String get itemOnions => 'Zwiebeln';

  @override
  String get itemApples => 'Äpfel';

  @override
  String get itemBananas => 'Bananen';

  @override
  String get itemChicken => 'Huhn';

  @override
  String get itemBeef => 'Rindfleisch';

  @override
  String get itemFish => 'Fisch';

  @override
  String get itemOliveOil => 'Olivenöl';

  @override
  String get itemSalt => 'Salz';

  @override
  String get itemSugar => 'Zucker';

  @override
  String get itemCoffee => 'Kaffee';

  @override
  String get itemTea => 'Tee';

  @override
  String get cannotAffectOthersScores => 'Sie sind nicht berechtigt, den Punktestand eines anderen Mitglieds zu ändern.';

  @override
  String get actionNotAllowed => 'Sie sind für diese Aktion nicht berechtigt.';

  @override
  String get somethingWentWrong => 'Es ist ein Fehler aufgetreten.';

  @override
  String get editorLabel => 'Bearbeiter';

  @override
  String get viewerLabel => 'Betrachter';

  @override
  String get roleUpdated => 'Rolle aktualisiert.';

  @override
  String updateFailed(Object error) {
    return 'Aktualisierung fehlgeschlagen: $error';
  }

  @override
  String get signIn => 'Anmelden';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get ok => 'OK';

  @override
  String get openInBrowser => 'Im Browser öffnen';

  @override
  String get privacyTitle => 'Datenschutzerklärung';

  @override
  String get menuPrivacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get errPermissionTitle => 'Berechtigung erforderlich';

  @override
  String get errPermissionBody => 'Sie haben keine Berechtigung für diese Aktion. Bitte wenden Sie sich an den Familieninhaber.';

  @override
  String get errSigninTitle => 'Anmeldung erforderlich';

  @override
  String get errSigninBody => 'Bitte melden Sie sich an, um fortzufahren.';

  @override
  String get errNetworkTitle => 'Netzwerkfehler';

  @override
  String get errNetworkBody => 'Es gab ein Verbindungsproblem. Bitte prüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.';

  @override
  String get errBusyTitle => 'Dienst ausgelastet';

  @override
  String get errBusyBody => 'Der Dienst ist vorübergehend nicht verfügbar. Bitte versuchen Sie es später erneut.';

  @override
  String get errNotFoundTitle => 'Nicht gefunden';

  @override
  String get errNotFoundBody => 'Die angeforderte Ressource wurde nicht gefunden.';

  @override
  String get errQuotaTitle => 'Limit erreicht';

  @override
  String get errQuotaBody => 'Das Nutzungs- oder Kontingentlimit wurde erreicht. Bitte versuchen Sie es später erneut.';

  @override
  String get errUnknownTitle => 'Etwas ist schiefgelaufen';

  @override
  String get errUnknownBody => 'Ein unerwarteter Fehler ist aufgetreten. Bitte versuchen Sie es erneut.';

  @override
  String get errTimeoutTitle => 'Zeitüberschreitung';

  @override
  String get errTimeoutBody => 'Die Anfrage hat die Zeitüberschreitung erreicht. Bitte erneut versuchen.';

  @override
  String get errAlreadyExistsTitle => 'Bereits vorhanden';

  @override
  String get errAlreadyExistsBody => 'Ein identischer Eintrag ist bereits vorhanden.';

  @override
  String get errInvalidTitle => 'Ungültige Eingabe';

  @override
  String get errInvalidBody => 'Die gesendeten Daten scheinen ungültig zu sein.';

  @override
  String get errPrecondTitle => 'Vorbedingung nicht erfüllt';

  @override
  String get errPrecondBody => 'Die Voraussetzungen für diesen Vorgang wurden nicht erfüllt.';

  @override
  String get errAbortedTitle => 'Vorgang abgebrochen';

  @override
  String get errAbortedBody => 'Der Vorgang wurde abgebrochen.';

  @override
  String get errCancelledTitle => 'Abgebrochen';

  @override
  String get errCancelledBody => 'Der Vorgang wurde abgebrochen.';

  @override
  String get errInternalTitle => 'Interner Fehler';

  @override
  String get errInternalBody => 'Es ist ein unerwarteter Serverfehler aufgetreten.';

  @override
  String get errDataLossTitle => 'Datenverlust';

  @override
  String get errDataLossBody => 'Während des Vorgangs ist ein Datenverlust aufgetreten.';

  @override
  String get errOutOfRangeTitle => 'Außerhalb des Bereichs';

  @override
  String get errOutOfRangeBody => 'Der Wert liegt außerhalb des zulässigen Bereichs.';

  @override
  String get errUnimplementedTitle => 'Nicht unterstützt';

  @override
  String get errUnimplementedBody => 'Dieses Feature wird noch nicht unterstützt.';
}

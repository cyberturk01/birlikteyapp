import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Togetherly'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addMember;

  /// No description provided for @pickMember.
  ///
  /// In en, this message translates to:
  /// **'Pick a member to continue'**
  String get pickMember;

  /// No description provided for @searchMember.
  ///
  /// In en, this message translates to:
  /// **'Search member…'**
  String get searchMember;

  /// No description provided for @noMembersFound.
  ///
  /// In en, this message translates to:
  /// **'No members found'**
  String get noMembersFound;

  /// No description provided for @seeAllMembers.
  ///
  /// In en, this message translates to:
  /// **'See all members ({count})'**
  String seeAllMembers(Object count);

  /// No description provided for @goToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to dashboard'**
  String get goToDashboard;

  /// No description provided for @setupFamily.
  ///
  /// In en, this message translates to:
  /// **'Let’s set up your family'**
  String get setupFamily;

  /// No description provided for @setupFamilyDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your first family member to start sharing tasks and shopping lists together.'**
  String get setupFamilyDesc;

  /// No description provided for @addFirstMember.
  ///
  /// In en, this message translates to:
  /// **'Add first member'**
  String get addFirstMember;

  /// No description provided for @setupFamilyHint.
  ///
  /// In en, this message translates to:
  /// **'You can add more members anytime from the top-right.'**
  String get setupFamilyHint;

  /// No description provided for @allMembers.
  ///
  /// In en, this message translates to:
  /// **'All members'**
  String get allMembers;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @showAllCount.
  ///
  /// In en, this message translates to:
  /// **'Show all ({count})'**
  String showAllCount(int count);

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @itemBoughtToast.
  ///
  /// In en, this message translates to:
  /// **'🎉 Item bought!'**
  String get itemBoughtToast;

  /// No description provided for @configTitle.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get configTitle;

  /// No description provided for @configSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize theme, reminders, and family filters.'**
  String get configSubtitle;

  /// No description provided for @familyInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Family Invitation Code'**
  String get familyInviteCode;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @appColor.
  ///
  /// In en, this message translates to:
  /// **'App color'**
  String get appColor;

  /// No description provided for @templates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// No description provided for @templatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-tap task & market packs'**
  String get templatesSubtitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @requestPermission.
  ///
  /// In en, this message translates to:
  /// **'Request permission'**
  String get requestPermission;

  /// No description provided for @permissionRequested.
  ///
  /// In en, this message translates to:
  /// **'Permission requested (if needed)'**
  String get permissionRequested;

  /// No description provided for @preciseAlarmsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open system setting to allow precise alarms'**
  String get preciseAlarmsTooltip;

  /// No description provided for @androidOnly.
  ///
  /// In en, this message translates to:
  /// **'This setting is Android-only'**
  String get androidOnly;

  /// No description provided for @enableExactAlarms.
  ///
  /// In en, this message translates to:
  /// **'Enable exact alarms'**
  String get enableExactAlarms;

  /// No description provided for @couldNotOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Could not open settings'**
  String get couldNotOpenSettings;

  /// No description provided for @menuManageFamily.
  ///
  /// In en, this message translates to:
  /// **'Manage family'**
  String get menuManageFamily;

  /// No description provided for @menuAddCenter.
  ///
  /// In en, this message translates to:
  /// **'Add Center'**
  String get menuAddCenter;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'DISMISS'**
  String get dismiss;

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @pendingToday.
  ///
  /// In en, this message translates to:
  /// **'Pending today'**
  String get pendingToday;

  /// No description provided for @toBuy.
  ///
  /// In en, this message translates to:
  /// **'To buy'**
  String get toBuy;

  /// No description provided for @totalRecords.
  ///
  /// In en, this message translates to:
  /// **'Total records'**
  String get totalRecords;

  /// No description provided for @pendingTasks.
  ///
  /// In en, this message translates to:
  /// **'Pending tasks'**
  String get pendingTasks;

  /// No description provided for @myTasks.
  ///
  /// In en, this message translates to:
  /// **'My tasks'**
  String get myTasks;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @itemsHeader.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsHeader;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @taskName.
  ///
  /// In en, this message translates to:
  /// **'Task name'**
  String get taskName;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItem;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get itemName;

  /// No description provided for @mine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get mine;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get noData;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @assignTask.
  ///
  /// In en, this message translates to:
  /// **'Assign task'**
  String get assignTask;

  /// No description provided for @assignItem.
  ///
  /// In en, this message translates to:
  /// **'Assign item'**
  String get assignItem;

  /// No description provided for @assignTo.
  ///
  /// In en, this message translates to:
  /// **'Assign to'**
  String get assignTo;

  /// No description provided for @noOne.
  ///
  /// In en, this message translates to:
  /// **'No one'**
  String get noOne;

  /// No description provided for @searchTasks.
  ///
  /// In en, this message translates to:
  /// **'Search tasks…'**
  String get searchTasks;

  /// No description provided for @searchItems.
  ///
  /// In en, this message translates to:
  /// **'Search items…'**
  String get searchItems;

  /// No description provided for @filterByAssignee.
  ///
  /// In en, this message translates to:
  /// **'Filter by assignee'**
  String get filterByAssignee;

  /// No description provided for @pendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingLabel;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get noTasks;

  /// No description provided for @clearCompleted.
  ///
  /// In en, this message translates to:
  /// **'Clear completed'**
  String get clearCompleted;

  /// No description provided for @completedTasksCleared.
  ///
  /// In en, this message translates to:
  /// **'Completed tasks cleared'**
  String get completedTasksCleared;

  /// No description provided for @markAllDone.
  ///
  /// In en, this message translates to:
  /// **'Mark all done'**
  String get markAllDone;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @editDueReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit (due/reminder)'**
  String get editDueReminder;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get noItems;

  /// No description provided for @clearBought.
  ///
  /// In en, this message translates to:
  /// **'Clear bought'**
  String get clearBought;

  /// No description provided for @boughtItemsCleared.
  ///
  /// In en, this message translates to:
  /// **'Bought items cleared'**
  String get boughtItemsCleared;

  /// No description provided for @markAllBought.
  ///
  /// In en, this message translates to:
  /// **'Mark all bought'**
  String get markAllBought;

  /// No description provided for @memberFallback.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberFallback;

  /// No description provided for @pendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Pending} one{Pending (1)} other{Pending ({count})}}'**
  String pendingCount(num count);

  /// No description provided for @completedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Completed} one{Completed (1)} other{Completed ({count})}}'**
  String completedCount(num count);

  /// No description provided for @toBuyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{To buy} one{To buy (1)} other{To buy ({count})}}'**
  String toBuyCount(num count);

  /// No description provided for @boughtCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Bought} one{Bought (1)} other{Bought ({count})}}'**
  String boughtCount(num count);

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @boughtLabel.
  ///
  /// In en, this message translates to:
  /// **'Bought'**
  String get boughtLabel;

  /// No description provided for @addTaskBtn.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTaskBtn;

  /// No description provided for @addItemBtn.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItemBtn;

  /// No description provided for @addTaskFor.
  ///
  /// In en, this message translates to:
  /// **'Add task for {name}'**
  String addTaskFor(String name);

  /// No description provided for @addItemFor.
  ///
  /// In en, this message translates to:
  /// **'Add item for {name}'**
  String addItemFor(String name);

  /// No description provided for @enterTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Enter tasks (comma or new line)…'**
  String get enterTasksHint;

  /// No description provided for @tasksHelperExample.
  ///
  /// In en, this message translates to:
  /// **'Example: Laundry, Dishes, Take out trash'**
  String get tasksHelperExample;

  /// No description provided for @enterItemsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter items (comma or new line)…'**
  String get enterItemsHint;

  /// No description provided for @itemsHelperExample.
  ///
  /// In en, this message translates to:
  /// **'Example: Milk, Bread, Eggs'**
  String get itemsHelperExample;

  /// No description provided for @suggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestionsTitle;

  /// No description provided for @addTypedList.
  ///
  /// In en, this message translates to:
  /// **'Add typed list'**
  String get addTypedList;

  /// No description provided for @itemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Item deleted'**
  String get itemDeleted;

  /// No description provided for @addSelected.
  ///
  /// In en, this message translates to:
  /// **'Add selected'**
  String get addSelected;

  /// No description provided for @addSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Add selected ({count})'**
  String addSelectedCount(int count);

  /// No description provided for @addedTasks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Added 1 task} other{Added {count} tasks}}'**
  String addedTasks(int count);

  /// No description provided for @addedItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Added 1 item} other{Added {count} items}}'**
  String addedItems(int count);

  /// No description provided for @clearedUndo.
  ///
  /// In en, this message translates to:
  /// **'Cleared – Undo'**
  String get clearedUndo;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @setDueDate.
  ///
  /// In en, this message translates to:
  /// **'Set due date'**
  String get setDueDate;

  /// No description provided for @setReminder.
  ///
  /// In en, this message translates to:
  /// **'Set reminder'**
  String get setReminder;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @duePrefix.
  ///
  /// In en, this message translates to:
  /// **'Due: {date}'**
  String duePrefix(String date);

  /// No description provided for @remindPrefix.
  ///
  /// In en, this message translates to:
  /// **'Remind: {date}'**
  String remindPrefix(String date);

  /// No description provided for @taskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get taskDeleted;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @taskCompletedToast.
  ///
  /// In en, this message translates to:
  /// **'🎉 Task completed!'**
  String get taskCompletedToast;

  /// No description provided for @pointsAwarded.
  ///
  /// In en, this message translates to:
  /// **'➕ +{points} points'**
  String pointsAwarded(int points);

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get lastMonth;

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses'**
  String get noExpenses;

  /// No description provided for @deleteExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete expense?'**
  String get deleteExpenseTitle;

  /// No description provided for @deleteExpenseBody.
  ///
  /// In en, this message translates to:
  /// **'“{title}” will be removed. You can undo right after.'**
  String deleteExpenseBody(String title);

  /// No description provided for @expenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted'**
  String get expenseDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailed(String error);

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @otherCategory.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherCategory;

  /// No description provided for @expensesInsightsTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Compose with: {expenses} — {insights}'**
  String expensesInsightsTitleHint(Object expenses, Object insights);

  /// No description provided for @memberLabel.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberLabel;

  /// No description provided for @byCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get byCategory;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @recordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 record} other{{count} records}}'**
  String recordsCount(int count);

  /// No description provided for @exportCsvTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsvTooltip;

  /// No description provided for @shareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareTooltip;

  /// No description provided for @noExpensesForRange.
  ///
  /// In en, this message translates to:
  /// **'No expenses for selected range.'**
  String get noExpensesForRange;

  /// No description provided for @savedCsvWithName.
  ///
  /// In en, this message translates to:
  /// **'Saved CSV: {name}'**
  String savedCsvWithName(String name);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Share failed: {error}'**
  String shareFailed(String error);

  /// No description provided for @changeCategory.
  ///
  /// In en, this message translates to:
  /// **'Change category'**
  String get changeCategory;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @customCategory.
  ///
  /// In en, this message translates to:
  /// **'Custom category'**
  String get customCategory;

  /// No description provided for @csvDate.
  ///
  /// In en, this message translates to:
  /// **'date'**
  String get csvDate;

  /// No description provided for @csvTitle.
  ///
  /// In en, this message translates to:
  /// **'title'**
  String get csvTitle;

  /// No description provided for @csvAmount.
  ///
  /// In en, this message translates to:
  /// **'amount'**
  String get csvAmount;

  /// No description provided for @csvMember.
  ///
  /// In en, this message translates to:
  /// **'member'**
  String get csvMember;

  /// No description provided for @csvCategory.
  ///
  /// In en, this message translates to:
  /// **'category'**
  String get csvCategory;

  /// No description provided for @expensesCsvShareText.
  ///
  /// In en, this message translates to:
  /// **'Togetherly — Expenses CSV'**
  String get expensesCsvShareText;

  /// No description provided for @categoryGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get categoryGroceries;

  /// No description provided for @categoryDining.
  ///
  /// In en, this message translates to:
  /// **'Dining'**
  String get categoryDining;

  /// No description provided for @categoryClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get categoryClothing;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categoryUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get categoryUtilities;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryKids.
  ///
  /// In en, this message translates to:
  /// **'Kids'**
  String get categoryKids;

  /// No description provided for @categoryHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get categoryHome;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @monthShortJan.
  ///
  /// In en, this message translates to:
  /// **'J'**
  String get monthShortJan;

  /// No description provided for @monthShortFeb.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get monthShortFeb;

  /// No description provided for @monthShortMar.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get monthShortMar;

  /// No description provided for @monthShortApr.
  ///
  /// In en, this message translates to:
  /// **'A'**
  String get monthShortApr;

  /// No description provided for @monthShortMay.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get monthShortMay;

  /// No description provided for @monthShortJun.
  ///
  /// In en, this message translates to:
  /// **'J'**
  String get monthShortJun;

  /// No description provided for @monthShortJul.
  ///
  /// In en, this message translates to:
  /// **'J'**
  String get monthShortJul;

  /// No description provided for @monthShortAug.
  ///
  /// In en, this message translates to:
  /// **'A'**
  String get monthShortAug;

  /// No description provided for @monthShortSep.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get monthShortSep;

  /// No description provided for @monthShortOct.
  ///
  /// In en, this message translates to:
  /// **'O'**
  String get monthShortOct;

  /// No description provided for @monthShortNov.
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get monthShortNov;

  /// No description provided for @monthShortDec.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get monthShortDec;

  /// No description provided for @expensesByCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses — By Category'**
  String get expensesByCategoryTitle;

  /// No description provided for @breakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get breakdown;

  /// No description provided for @trend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get trend;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @totalsByCategory.
  ///
  /// In en, this message translates to:
  /// **'Totals by category'**
  String get totalsByCategory;

  /// No description provided for @editBudgetTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get editBudgetTooltip;

  /// No description provided for @budgetDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget — {category}'**
  String budgetDialogTitle(String category);

  /// No description provided for @monthlyBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget'**
  String get monthlyBudgetLabel;

  /// No description provided for @monthlyBudgetHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 250'**
  String get monthlyBudgetHint;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @budgetUpdatedFor.
  ///
  /// In en, this message translates to:
  /// **'Budget updated for {category}'**
  String budgetUpdatedFor(String category);

  /// No description provided for @last6MonthsByCategory.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months by category'**
  String get last6MonthsByCategory;

  /// No description provided for @noDataLastMonths.
  ///
  /// In en, this message translates to:
  /// **'No data for last months.'**
  String get noDataLastMonths;

  /// No description provided for @categoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Category — {category}'**
  String categoryTitle(String category);

  /// No description provided for @budgetsMenu.
  ///
  /// In en, this message translates to:
  /// **'Budgets…'**
  String get budgetsMenu;

  /// No description provided for @inviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied: {code}'**
  String inviteCodeCopied(String code);

  /// No description provided for @ownerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerLabel;

  /// No description provided for @editMember.
  ///
  /// In en, this message translates to:
  /// **'Edit member'**
  String get editMember;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @removeUser.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get removeUser;

  /// No description provided for @photoUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo update failed: {error}'**
  String photoUpdateFailed(String error);

  /// No description provided for @removeFailed.
  ///
  /// In en, this message translates to:
  /// **'Remove failed: {error}'**
  String removeFailed(String error);

  /// No description provided for @memberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get memberRemoved;

  /// No description provided for @removeMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove member?'**
  String get removeMemberTitle;

  /// No description provided for @removeMemberBody.
  ///
  /// In en, this message translates to:
  /// **'“{name}” will be removed from this family.'**
  String removeMemberBody(String name);

  /// No description provided for @inviteMember.
  ///
  /// In en, this message translates to:
  /// **'Invite a member'**
  String get inviteMember;

  /// No description provided for @shareInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Share your family’s invite code'**
  String get shareInviteCode;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @copyAndShare.
  ///
  /// In en, this message translates to:
  /// **'Copy & Share'**
  String get copyAndShare;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// No description provided for @noFamilyMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No family members yet'**
  String get noFamilyMembersYet;

  /// No description provided for @useInviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Use the invite code above to add members.'**
  String get useInviteCodeHint;

  /// No description provided for @editMemberLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit member label'**
  String get editMemberLabel;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @setupYourFamily.
  ///
  /// In en, this message translates to:
  /// **'Set up your family'**
  String get setupYourFamily;

  /// No description provided for @createFamilyTab.
  ///
  /// In en, this message translates to:
  /// **'Create family'**
  String get createFamilyTab;

  /// No description provided for @joinWithCodeTab.
  ///
  /// In en, this message translates to:
  /// **'Join with code'**
  String get joinWithCodeTab;

  /// No description provided for @chooseFamilyName.
  ///
  /// In en, this message translates to:
  /// **'Choose a family name'**
  String get chooseFamilyName;

  /// No description provided for @familyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Family name'**
  String get familyNameLabel;

  /// No description provided for @familyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Johnson Family'**
  String get familyNameHint;

  /// No description provided for @nameCheckingOk.
  ///
  /// In en, this message translates to:
  /// **'Great! This name is available.'**
  String get nameCheckingOk;

  /// No description provided for @nameCheckingTaken.
  ///
  /// In en, this message translates to:
  /// **'This name is taken. Try one of these:'**
  String get nameCheckingTaken;

  /// No description provided for @createFamilyCta.
  ///
  /// In en, this message translates to:
  /// **'Create family'**
  String get createFamilyCta;

  /// No description provided for @joinExistingFamily.
  ///
  /// In en, this message translates to:
  /// **'Join an existing family'**
  String get joinExistingFamily;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCodeLabel;

  /// No description provided for @inviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., ABCD23'**
  String get inviteCodeHint;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @joinFamilyCta.
  ///
  /// In en, this message translates to:
  /// **'Join family'**
  String get joinFamilyCta;

  /// No description provided for @errorFamilyNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Family name cannot be empty'**
  String get errorFamilyNameEmpty;

  /// No description provided for @errorNameUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This name is currently unavailable'**
  String get errorNameUnavailable;

  /// No description provided for @errorInviteEmpty.
  ///
  /// In en, this message translates to:
  /// **'Invite code cannot be empty'**
  String get errorInviteEmpty;

  /// No description provided for @errorInviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid invite code'**
  String get errorInviteInvalid;

  /// No description provided for @inviteYourFamily.
  ///
  /// In en, this message translates to:
  /// **'Invite your family'**
  String get inviteYourFamily;

  /// No description provided for @inviteShareHelp.
  ///
  /// In en, this message translates to:
  /// **'Share this code with your family to join your home.'**
  String get inviteShareHelp;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @inviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Join our family on Togetherly: {code}'**
  String inviteShareText(String code);

  /// No description provided for @weeklyTaskPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Task Plan'**
  String get weeklyTaskPlanTitle;

  /// No description provided for @weeklyTaskPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan weekly routines and assign them to your family.'**
  String get weeklyTaskPlanSubtitle;

  /// No description provided for @defaultTime.
  ///
  /// In en, this message translates to:
  /// **'Default time'**
  String get defaultTime;

  /// No description provided for @addToDayShort.
  ///
  /// In en, this message translates to:
  /// **'Add to {day}'**
  String addToDayShort(String day);

  /// No description provided for @noWeeklyTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noWeeklyTasks;

  /// No description provided for @addTaskForDay.
  ///
  /// In en, this message translates to:
  /// **'Add task for {day}'**
  String addTaskForDay(String day);

  /// No description provided for @enterTaskHint.
  ///
  /// In en, this message translates to:
  /// **'Enter task…'**
  String get enterTaskHint;

  /// No description provided for @assignToOptional.
  ///
  /// In en, this message translates to:
  /// **'Assign to (optional)'**
  String get assignToOptional;

  /// No description provided for @addedToDay.
  ///
  /// In en, this message translates to:
  /// **'Added to {day}'**
  String addedToDay(String day);

  /// No description provided for @addedToDayAndSynced.
  ///
  /// In en, this message translates to:
  /// **'Added to {day} and synced to Tasks'**
  String addedToDayAndSynced(String day);

  /// No description provided for @defaultWeeklyReminderSaved.
  ///
  /// In en, this message translates to:
  /// **'Default weekly reminder time saved'**
  String get defaultWeeklyReminderSaved;

  /// No description provided for @onLabel.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get onLabel;

  /// No description provided for @offLabel.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get offLabel;

  /// No description provided for @disableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Disable notifications'**
  String get disableNotifications;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enableNotifications;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationsDisabled;

  /// No description provided for @setTime.
  ///
  /// In en, this message translates to:
  /// **'Set time'**
  String get setTime;

  /// No description provided for @clearTime.
  ///
  /// In en, this message translates to:
  /// **'Clear time'**
  String get clearTime;

  /// No description provided for @reminderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Reminder updated'**
  String get reminderUpdated;

  /// No description provided for @reminderTimeCleared.
  ///
  /// In en, this message translates to:
  /// **'Reminder time cleared'**
  String get reminderTimeCleared;

  /// No description provided for @editWeeklyTask.
  ///
  /// In en, this message translates to:
  /// **'Edit weekly task'**
  String get editWeeklyTask;

  /// No description provided for @dayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayLabel;

  /// No description provided for @assignToLabel.
  ///
  /// In en, this message translates to:
  /// **'Assign to'**
  String get assignToLabel;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @notificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsLabel;

  /// No description provided for @weeklyTaskUpdated.
  ///
  /// In en, this message translates to:
  /// **'Weekly task updated'**
  String get weeklyTaskUpdated;

  /// No description provided for @weekdayShortMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayShortMon;

  /// No description provided for @weekdayShortTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayShortTue;

  /// No description provided for @weekdayShortWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayShortWed;

  /// No description provided for @weekdayShortThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayShortThu;

  /// No description provided for @weekdayShortFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayShortFri;

  /// No description provided for @weekdayShortSat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdayShortSat;

  /// No description provided for @weekdayShortSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdayShortSun;

  /// No description provided for @weekdayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdaySunday;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get editExpense;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @recentLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentLabel;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @amountGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get amountGreaterThanZero;

  /// No description provided for @addedAmount.
  ///
  /// In en, this message translates to:
  /// **'Added {amount}'**
  String addedAmount(String amount);

  /// No description provided for @updatedAmount.
  ///
  /// In en, this message translates to:
  /// **'Updated {amount}'**
  String updatedAmount(String amount);

  /// No description provided for @saveFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String saveFailedWithError(String error);

  /// No description provided for @noActiveFamily.
  ///
  /// In en, this message translates to:
  /// **'No active family'**
  String get noActiveFamily;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @quickAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get quickAddTitle;

  /// No description provided for @quickAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add new tasks and market items in one place.'**
  String get quickAddSubtitle;

  /// No description provided for @allTasksHeader.
  ///
  /// In en, this message translates to:
  /// **'All tasks'**
  String get allTasksHeader;

  /// No description provided for @allItemsHeader.
  ///
  /// In en, this message translates to:
  /// **'All items'**
  String get allItemsHeader;

  /// No description provided for @enterTaskHintShort.
  ///
  /// In en, this message translates to:
  /// **'Enter task…'**
  String get enterTaskHintShort;

  /// No description provided for @enterItemHintShort.
  ///
  /// In en, this message translates to:
  /// **'Enter item…'**
  String get enterItemHintShort;

  /// No description provided for @taskAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This task already exists'**
  String get taskAlreadyExists;

  /// No description provided for @itemAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This item already exists'**
  String get itemAlreadyExists;

  /// No description provided for @taskAddedToast.
  ///
  /// In en, this message translates to:
  /// **'Task added'**
  String get taskAddedToast;

  /// No description provided for @itemAddedToast.
  ///
  /// In en, this message translates to:
  /// **'Item added'**
  String get itemAddedToast;

  /// No description provided for @editNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editNameTitle;

  /// No description provided for @assignTooltip.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assignTooltip;

  /// No description provided for @editTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editTooltip;

  /// No description provided for @taskTakeOutTrash.
  ///
  /// In en, this message translates to:
  /// **'Take out the trash'**
  String get taskTakeOutTrash;

  /// No description provided for @taskCleanKitchen.
  ///
  /// In en, this message translates to:
  /// **'Clean the kitchen'**
  String get taskCleanKitchen;

  /// No description provided for @taskDoLaundry.
  ///
  /// In en, this message translates to:
  /// **'Do the laundry'**
  String get taskDoLaundry;

  /// No description provided for @taskVacuumLiving.
  ///
  /// In en, this message translates to:
  /// **'Vacuum the living room'**
  String get taskVacuumLiving;

  /// No description provided for @taskWashDishes.
  ///
  /// In en, this message translates to:
  /// **'Wash the dishes'**
  String get taskWashDishes;

  /// No description provided for @taskWaterPlants.
  ///
  /// In en, this message translates to:
  /// **'Water the plants'**
  String get taskWaterPlants;

  /// No description provided for @taskCookDinner.
  ///
  /// In en, this message translates to:
  /// **'Cook dinner'**
  String get taskCookDinner;

  /// No description provided for @taskOrganizeFridge.
  ///
  /// In en, this message translates to:
  /// **'Organize the fridge'**
  String get taskOrganizeFridge;

  /// No description provided for @taskChangeBedsheets.
  ///
  /// In en, this message translates to:
  /// **'Change bedsheets'**
  String get taskChangeBedsheets;

  /// No description provided for @taskIronClothes.
  ///
  /// In en, this message translates to:
  /// **'Iron clothes'**
  String get taskIronClothes;

  /// No description provided for @itemMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get itemMilk;

  /// No description provided for @itemBread.
  ///
  /// In en, this message translates to:
  /// **'Bread'**
  String get itemBread;

  /// No description provided for @itemEggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get itemEggs;

  /// No description provided for @itemButter.
  ///
  /// In en, this message translates to:
  /// **'Butter'**
  String get itemButter;

  /// No description provided for @itemCheese.
  ///
  /// In en, this message translates to:
  /// **'Cheese'**
  String get itemCheese;

  /// No description provided for @itemRice.
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get itemRice;

  /// No description provided for @itemPasta.
  ///
  /// In en, this message translates to:
  /// **'Pasta'**
  String get itemPasta;

  /// No description provided for @itemTomatoes.
  ///
  /// In en, this message translates to:
  /// **'Tomatoes'**
  String get itemTomatoes;

  /// No description provided for @itemPotatoes.
  ///
  /// In en, this message translates to:
  /// **'Potatoes'**
  String get itemPotatoes;

  /// No description provided for @itemOnions.
  ///
  /// In en, this message translates to:
  /// **'Onions'**
  String get itemOnions;

  /// No description provided for @itemApples.
  ///
  /// In en, this message translates to:
  /// **'Apples'**
  String get itemApples;

  /// No description provided for @itemBananas.
  ///
  /// In en, this message translates to:
  /// **'Bananas'**
  String get itemBananas;

  /// No description provided for @itemChicken.
  ///
  /// In en, this message translates to:
  /// **'Chicken'**
  String get itemChicken;

  /// No description provided for @itemBeef.
  ///
  /// In en, this message translates to:
  /// **'Beef'**
  String get itemBeef;

  /// No description provided for @itemFish.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get itemFish;

  /// No description provided for @itemOliveOil.
  ///
  /// In en, this message translates to:
  /// **'Olive oil'**
  String get itemOliveOil;

  /// No description provided for @itemSalt.
  ///
  /// In en, this message translates to:
  /// **'Salt'**
  String get itemSalt;

  /// No description provided for @itemSugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get itemSugar;

  /// No description provided for @itemCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get itemCoffee;

  /// No description provided for @itemTea.
  ///
  /// In en, this message translates to:
  /// **'Tea'**
  String get itemTea;

  /// No description provided for @cannotAffectOthersScores.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to change another member’s points.'**
  String get cannotAffectOthersScores;

  /// No description provided for @actionNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to perform this action.'**
  String get actionNotAllowed;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get somethingWentWrong;

  /// No description provided for @editorLabel.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editorLabel;

  /// No description provided for @viewerLabel.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get viewerLabel;

  /// No description provided for @roleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Role updated.'**
  String get roleUpdated;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String updateFailed(Object error);

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'tr': return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

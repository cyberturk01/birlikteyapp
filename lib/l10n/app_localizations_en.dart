// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Togetherly';

  @override
  String get welcome => 'Welcome';

  @override
  String get tasks => 'Tasks';

  @override
  String get items => 'Items';

  @override
  String get expenses => 'Expenses';

  @override
  String get weekly => 'Weekly Plan';

  @override
  String get members => 'Members';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get signOut => 'Sign out';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get addMember => 'Add member';

  @override
  String get pickMember => 'Pick a member to continue';

  @override
  String get searchMember => 'Search member…';

  @override
  String get noMembersFound => 'No members found';

  @override
  String seeAllMembers(Object count) {
    return 'See all members ($count)';
  }

  @override
  String get goToDashboard => 'Go to dashboard';

  @override
  String get setupFamily => 'Let’s set up your family';

  @override
  String get setupFamilyDesc => 'Add your first family member to start sharing tasks and shopping lists together.';

  @override
  String get addFirstMember => 'Add first member';

  @override
  String get setupFamilyHint => 'You can add more members anytime from the top-right.';

  @override
  String get allMembers => 'All members';

  @override
  String get showLess => 'Show less';

  @override
  String get showAll => 'Show all';

  @override
  String showAllCount(int count) {
    return 'Show all ($count)';
  }

  @override
  String get category => 'Category';

  @override
  String get price => 'Price';

  @override
  String get itemBoughtToast => '🎉 Item bought!';

  @override
  String get configTitle => 'Configuration';

  @override
  String get configSubtitle => 'Customize theme, reminders, and family filters.';

  @override
  String get familyInviteCode => 'Family Invitation Code';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get appColor => 'App color';

  @override
  String get templates => 'Templates';

  @override
  String get templatesSubtitle => 'One-tap task & market packs';

  @override
  String get notifications => 'Notifications';

  @override
  String get requestPermission => 'Request permission';

  @override
  String get permissionRequested => 'Permission requested (if needed)';

  @override
  String get preciseAlarmsTooltip => 'Open system setting to allow precise alarms';

  @override
  String get androidOnly => 'This setting is Android-only';

  @override
  String get enableExactAlarms => 'Enable exact alarms';

  @override
  String get couldNotOpenSettings => 'Could not open settings';

  @override
  String get menuManageFamily => 'Manage family';

  @override
  String get menuAddCenter => 'Add Center';

  @override
  String get dismiss => 'DISMISS';

  @override
  String get market => 'Market';

  @override
  String get pendingToday => 'Pending today';

  @override
  String get toBuy => 'To buy';

  @override
  String get totalRecords => 'Total records';

  @override
  String get pendingTasks => 'Pending tasks';

  @override
  String get myTasks => 'My tasks';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get itemsHeader => 'Items';

  @override
  String get edit => 'Edit';

  @override
  String get editTask => 'Edit task';

  @override
  String get taskName => 'Task name';

  @override
  String get editItem => 'Edit item';

  @override
  String get itemName => 'Item name';

  @override
  String get mine => 'Mine';

  @override
  String get noData => 'No Data';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get assignTask => 'Assign task';

  @override
  String get assignItem => 'Assign item';

  @override
  String get assignTo => 'Assign to';

  @override
  String get noOne => 'No one';

  @override
  String get searchTasks => 'Search tasks…';

  @override
  String get searchItems => 'Search items…';

  @override
  String get filterByAssignee => 'Filter by assignee';

  @override
  String get pendingLabel => 'Pending';

  @override
  String get allLabel => 'All';

  @override
  String get noTasks => 'No tasks';

  @override
  String get clearCompleted => 'Clear completed';

  @override
  String get completedTasksCleared => 'Completed tasks cleared';

  @override
  String get markAllDone => 'Mark all done';

  @override
  String get rename => 'Rename';

  @override
  String get assign => 'Assign';

  @override
  String get delete => 'Delete';

  @override
  String get editDueReminder => 'Edit (due/reminder)';

  @override
  String get noItems => 'No items';

  @override
  String get clearBought => 'Clear bought';

  @override
  String get boughtItemsCleared => 'Bought items cleared';

  @override
  String get markAllBought => 'Mark all bought';

  @override
  String get memberFallback => 'Member';

  @override
  String pendingCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pending ($count)',
      one: 'Pending (1)',
      zero: 'Pending',
    );
    return '$_temp0';
  }

  @override
  String completedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Completed ($count)',
      one: 'Completed (1)',
      zero: 'Completed',
    );
    return '$_temp0';
  }

  @override
  String toBuyCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'To buy ($count)',
      one: 'To buy (1)',
      zero: 'To buy',
    );
    return '$_temp0';
  }

  @override
  String boughtCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bought ($count)',
      one: 'Bought (1)',
      zero: 'Bought',
    );
    return '$_temp0';
  }

  @override
  String get completedLabel => 'Completed';

  @override
  String get boughtLabel => 'Bought';

  @override
  String get addTaskBtn => 'Add task';

  @override
  String get addItemBtn => 'Add item';

  @override
  String addTaskFor(String name) {
    return 'Add task for $name';
  }

  @override
  String addItemFor(String name) {
    return 'Add item for $name';
  }

  @override
  String get enterTasksHint => 'Enter tasks (comma or new line)…';

  @override
  String get tasksHelperExample => 'Example: Laundry, Dishes, Take out trash';

  @override
  String get enterItemsHint => 'Enter items (comma or new line)…';

  @override
  String get itemsHelperExample => 'Example: Milk, Bread, Eggs';

  @override
  String get suggestionsTitle => 'Suggestions';

  @override
  String get addTypedList => 'Add typed list';

  @override
  String get itemDeleted => 'Item deleted';

  @override
  String get addSelected => 'Add selected';

  @override
  String addSelectedCount(int count) {
    return 'Add selected ($count)';
  }

  @override
  String addedTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count tasks',
      one: 'Added 1 task',
    );
    return '$_temp0';
  }

  @override
  String addedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count items',
      one: 'Added 1 item',
    );
    return '$_temp0';
  }

  @override
  String get clearedUndo => 'Cleared – Undo';

  @override
  String get undo => 'Undo';

  @override
  String get setDueDate => 'Set due date';

  @override
  String get setReminder => 'Set reminder';

  @override
  String get clear => 'Clear';

  @override
  String duePrefix(String date) {
    return 'Due: $date';
  }

  @override
  String remindPrefix(String date) {
    return 'Remind: $date';
  }

  @override
  String get taskDeleted => 'Task deleted';

  @override
  String get more => 'More';

  @override
  String get taskCompletedToast => '🎉 Task completed!';

  @override
  String pointsAwarded(int points) {
    return '➕ +$points points';
  }

  @override
  String get thisMonth => 'This month';

  @override
  String get lastMonth => 'Last month';

  @override
  String get noExpenses => 'No expenses';

  @override
  String get deleteExpenseTitle => 'Delete expense?';

  @override
  String deleteExpenseBody(String title) {
    return '“$title” will be removed. You can undo right after.';
  }

  @override
  String get expenseDeleted => 'Expense deleted';

  @override
  String deleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get addExpense => 'Add expense';

  @override
  String get insights => 'Insights';

  @override
  String get otherCategory => 'Other';

  @override
  String expensesInsightsTitleHint(Object expenses, Object insights) {
    return 'Compose with: $expenses — $insights';
  }

  @override
  String get memberLabel => 'Member';

  @override
  String get byCategory => 'By category';

  @override
  String get export => 'Export';

  @override
  String get share => 'Share';

  @override
  String get transactions => 'Transactions';

  @override
  String recordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return '$_temp0';
  }

  @override
  String get exportCsvTooltip => 'Export CSV';

  @override
  String get shareTooltip => 'Share';

  @override
  String get noExpensesForRange => 'No expenses for selected range.';

  @override
  String savedCsvWithName(String name) {
    return 'Saved CSV: $name';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String shareFailed(String error) {
    return 'Share failed: $error';
  }

  @override
  String get changeCategory => 'Change category';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get customCategory => 'Custom category';

  @override
  String get csvDate => 'date';

  @override
  String get csvTitle => 'title';

  @override
  String get csvAmount => 'amount';

  @override
  String get csvMember => 'member';

  @override
  String get csvCategory => 'category';

  @override
  String get expensesCsvShareText => 'Togetherly — Expenses CSV';

  @override
  String get categoryGroceries => 'Groceries';

  @override
  String get categoryDining => 'Dining';

  @override
  String get categoryClothing => 'Clothing';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryUtilities => 'Utilities';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryKids => 'Kids';

  @override
  String get categoryHome => 'Home';

  @override
  String get categoryOther => 'Other';

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
  String get expensesByCategoryTitle => 'Expenses — By Category';

  @override
  String get breakdown => 'Breakdown';

  @override
  String get trend => 'Trend';

  @override
  String get member => 'Member';

  @override
  String get totalsByCategory => 'Totals by category';

  @override
  String get editBudgetTooltip => 'Edit budget';

  @override
  String budgetDialogTitle(String category) {
    return 'Budget — $category';
  }

  @override
  String get monthlyBudgetLabel => 'Monthly budget';

  @override
  String get monthlyBudgetHint => 'e.g. 250';

  @override
  String get remove => 'Remove';

  @override
  String budgetUpdatedFor(String category) {
    return 'Budget updated for $category';
  }

  @override
  String get last6MonthsByCategory => 'Last 6 months by category';

  @override
  String get noDataLastMonths => 'No data for last months.';

  @override
  String categoryTitle(String category) {
    return 'Category — $category';
  }

  @override
  String get budgetsMenu => 'Budgets…';

  @override
  String inviteCodeCopied(String code) {
    return 'Invite code copied: $code';
  }

  @override
  String get ownerLabel => 'Owner';

  @override
  String get editMember => 'Edit member';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get removeUser => 'Remove member';

  @override
  String photoUpdateFailed(String error) {
    return 'Photo update failed: $error';
  }

  @override
  String removeFailed(String error) {
    return 'Remove failed: $error';
  }

  @override
  String get memberRemoved => 'Member removed';

  @override
  String get removeMemberTitle => 'Remove member?';

  @override
  String removeMemberBody(String name) {
    return '“$name” will be removed from this family.';
  }

  @override
  String get inviteMember => 'Invite a member';

  @override
  String get shareInviteCode => 'Share your family’s invite code';

  @override
  String get copyCode => 'Copy code';

  @override
  String get copyAndShare => 'Copy & Share';

  @override
  String get inviteCode => 'Invite code';

  @override
  String get noFamilyMembersYet => 'No family members yet';

  @override
  String get useInviteCodeHint => 'Use the invite code above to add members.';

  @override
  String get editMemberLabel => 'Edit member label';

  @override
  String get label => 'Label';

  @override
  String get setupYourFamily => 'Set up your family';

  @override
  String get createFamilyTab => 'Create family';

  @override
  String get joinWithCodeTab => 'Join with code';

  @override
  String get chooseFamilyName => 'Choose a family name';

  @override
  String get familyNameLabel => 'Family name';

  @override
  String get familyNameHint => 'e.g., Johnson Family';

  @override
  String get nameCheckingOk => 'Great! This name is available.';

  @override
  String get nameCheckingTaken => 'This name is taken. Try one of these:';

  @override
  String get createFamilyCta => 'Create family';

  @override
  String get joinExistingFamily => 'Join an existing family';

  @override
  String get inviteCodeLabel => 'Invite code';

  @override
  String get inviteCodeHint => 'e.g., ABCD23';

  @override
  String get paste => 'Paste';

  @override
  String get joinFamilyCta => 'Join family';

  @override
  String get errorFamilyNameEmpty => 'Family name cannot be empty';

  @override
  String get errorNameUnavailable => 'This name is currently unavailable';

  @override
  String get errorInviteEmpty => 'Invite code cannot be empty';

  @override
  String get errorInviteInvalid => 'Invalid invite code';

  @override
  String get inviteYourFamily => 'Invite your family';

  @override
  String get inviteShareHelp => 'Share this code with your family to join your home.';

  @override
  String get copy => 'Copy';

  @override
  String get done => 'Done';

  @override
  String inviteShareText(String code) {
    return 'Join our family on Togetherly: $code';
  }

  @override
  String get weeklyTaskPlanTitle => 'Weekly Task Plan';

  @override
  String get weeklyTaskPlanSubtitle => 'Plan weekly routines and assign them to your family.';

  @override
  String get defaultTime => 'Default time';

  @override
  String addToDayShort(String day) {
    return 'Add to $day';
  }

  @override
  String get noWeeklyTasks => 'No tasks yet';

  @override
  String addTaskForDay(String day) {
    return 'Add task for $day';
  }

  @override
  String get enterTaskHint => 'Enter task…';

  @override
  String get assignToOptional => 'Assign to (optional)';

  @override
  String addedToDay(String day) {
    return 'Added to $day';
  }

  @override
  String addedToDayAndSynced(String day) {
    return 'Added to $day and synced to Tasks';
  }

  @override
  String get defaultWeeklyReminderSaved => 'Default weekly reminder time saved';

  @override
  String get onLabel => 'On';

  @override
  String get offLabel => 'Off';

  @override
  String get familyMap => 'Family Map';

  @override
  String get shareLoc => 'Share Location';

  @override
  String get disableNotifications => 'Disable notifications';

  @override
  String get enableNotifications => 'Enable notifications';

  @override
  String get notificationsEnabled => 'Notifications enabled';

  @override
  String get notificationsDisabled => 'Notifications disabled';

  @override
  String get setTime => 'Set time';

  @override
  String get clearTime => 'Clear time';

  @override
  String get reminderUpdated => 'Reminder updated';

  @override
  String get reminderTimeCleared => 'Reminder time cleared';

  @override
  String get editWeeklyTask => 'Edit weekly task';

  @override
  String get dayLabel => 'Day';

  @override
  String get assignToLabel => 'Assign to';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get notSet => 'Not set';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get weeklyTaskUpdated => 'Weekly task updated';

  @override
  String get weekdayShortMon => 'Mon';

  @override
  String get weekdayShortTue => 'Tue';

  @override
  String get weekdayShortWed => 'Wed';

  @override
  String get weekdayShortThu => 'Thu';

  @override
  String get weekdayShortFri => 'Fri';

  @override
  String get weekdayShortSat => 'Sat';

  @override
  String get weekdayShortSun => 'Sun';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get editExpense => 'Edit expense';

  @override
  String get titleLabel => 'Title';

  @override
  String get amountLabel => 'Amount';

  @override
  String get newCategory => 'New category';

  @override
  String get nameLabel => 'Name';

  @override
  String get recentLabel => 'Recent';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get enterValidAmount => 'Enter a valid amount';

  @override
  String get amountGreaterThanZero => 'Amount must be greater than 0';

  @override
  String addedAmount(String amount) {
    return 'Added $amount';
  }

  @override
  String updatedAmount(String amount) {
    return 'Updated $amount';
  }

  @override
  String saveFailedWithError(String error) {
    return 'Failed: $error';
  }

  @override
  String get noActiveFamily => 'No active family';

  @override
  String get add => 'Add';

  @override
  String get week => 'Week';

  @override
  String get today => 'Today';

  @override
  String get month => 'Month';

  @override
  String get quickAddTitle => 'Quick Add';

  @override
  String get quickAddSubtitle => 'Add new tasks and market items in one place.';

  @override
  String get allTasksHeader => 'All tasks';

  @override
  String get allItemsHeader => 'All items';

  @override
  String get enterTaskHintShort => 'Enter task…';

  @override
  String get enterItemHintShort => 'Enter item…';

  @override
  String get taskAlreadyExists => 'This task already exists';

  @override
  String get itemAlreadyExists => 'This item already exists';

  @override
  String get taskAddedToast => 'Task added';

  @override
  String get itemAddedToast => 'Item added';

  @override
  String get editNameTitle => 'Edit name';

  @override
  String get assignTooltip => 'Assign';

  @override
  String get editTooltip => 'Edit';

  @override
  String get taskTakeOutTrash => 'Take out the trash';

  @override
  String get taskCleanKitchen => 'Clean the kitchen';

  @override
  String get taskDoLaundry => 'Do the laundry';

  @override
  String get taskVacuumLiving => 'Vacuum the living room';

  @override
  String get taskWashDishes => 'Wash the dishes';

  @override
  String get taskWaterPlants => 'Water the plants';

  @override
  String get taskCookDinner => 'Cook dinner';

  @override
  String get taskOrganizeFridge => 'Organize the fridge';

  @override
  String get taskChangeBedsheets => 'Change bedsheets';

  @override
  String get taskIronClothes => 'Iron clothes';

  @override
  String get itemMilk => 'Milk';

  @override
  String get itemBread => 'Bread';

  @override
  String get itemEggs => 'Eggs';

  @override
  String get itemButter => 'Butter';

  @override
  String get itemCheese => 'Cheese';

  @override
  String get itemRice => 'Rice';

  @override
  String get itemPasta => 'Pasta';

  @override
  String get itemTomatoes => 'Tomatoes';

  @override
  String get itemPotatoes => 'Potatoes';

  @override
  String get itemOnions => 'Onions';

  @override
  String get itemApples => 'Apples';

  @override
  String get itemBananas => 'Bananas';

  @override
  String get itemChicken => 'Chicken';

  @override
  String get itemBeef => 'Beef';

  @override
  String get itemFish => 'Fish';

  @override
  String get itemOliveOil => 'Olive oil';

  @override
  String get itemSalt => 'Salt';

  @override
  String get itemSugar => 'Sugar';

  @override
  String get itemCoffee => 'Coffee';

  @override
  String get itemTea => 'Tea';

  @override
  String get cannotAffectOthersScores => 'You do not have permission to change another member’s points.';

  @override
  String get actionNotAllowed => 'You are not allowed to perform this action.';

  @override
  String get somethingWentWrong => 'Something went wrong.';

  @override
  String get editorLabel => 'Editor';

  @override
  String get viewerLabel => 'Viewer';

  @override
  String get roleUpdated => 'Role updated.';

  @override
  String updateFailed(Object error) {
    return 'Update failed: $error';
  }

  @override
  String get signIn => 'Sign in';

  @override
  String get retry => 'Retry';

  @override
  String get ok => 'OK';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get privacyTitle => 'Privacy Policy';

  @override
  String get menuPrivacyPolicy => 'PrivacyPolicy';

  @override
  String get errPermissionTitle => 'Permission required';

  @override
  String get errPermissionBody => 'You don’t have permission to perform this action. Please contact the family owner.';

  @override
  String get errSigninTitle => 'Sign in required';

  @override
  String get errSigninBody => 'Please sign in to continue.';

  @override
  String get errNetworkTitle => 'Network error';

  @override
  String get errNetworkBody => 'There was a connection problem. Please check your internet and try again.';

  @override
  String get errBusyTitle => 'Service is busy';

  @override
  String get errBusyBody => 'The service is temporarily unavailable. Please try again shortly.';

  @override
  String get errNotFoundTitle => 'Not found';

  @override
  String get errNotFoundBody => 'The requested resource could not be found.';

  @override
  String get errQuotaTitle => 'Limit reached';

  @override
  String get errQuotaBody => 'Usage limit or quota has been reached. Please try again later.';

  @override
  String get errUnknownTitle => 'Something went wrong';

  @override
  String get errUnknownBody => 'An unexpected error occurred. Please try again.';

  @override
  String get errTimeoutTitle => 'Timeout';

  @override
  String get errTimeoutBody => 'The request timed out. Please try again.';

  @override
  String get errAlreadyExistsTitle => 'Already Exists';

  @override
  String get errAlreadyExistsBody => 'An identical record already exists.';

  @override
  String get errInvalidTitle => 'Invalid Input';

  @override
  String get errInvalidBody => 'The data you sent appears to be invalid.';

  @override
  String get errPrecondTitle => 'Failed Precondition';

  @override
  String get errPrecondBody => 'Preconditions for this operation were not met.';

  @override
  String get errAbortedTitle => 'Operation Aborted';

  @override
  String get errAbortedBody => 'The operation was aborted.';

  @override
  String get errCancelledTitle => 'Cancelled';

  @override
  String get errCancelledBody => 'The operation was cancelled.';

  @override
  String get errInternalTitle => 'Internal Error';

  @override
  String get errInternalBody => 'An unexpected server error occurred.';

  @override
  String get errDataLossTitle => 'Data Loss';

  @override
  String get errDataLossBody => 'Data loss occurred during the operation.';

  @override
  String get errOutOfRangeTitle => 'Out of Range';

  @override
  String get errOutOfRangeBody => 'The value is out of the permitted range.';

  @override
  String get errUnimplementedTitle => 'Not Supported';

  @override
  String get errUnimplementedBody => 'This feature is not supported yet.';

  @override
  String get locSharingStarted => 'Live location sharing started.';

  @override
  String get locSharingStopped => 'Live location sharing stopped.';

  @override
  String get locLiveOn => 'Live location is ON';

  @override
  String get locPermNeeded => 'Location permission is required.';

  @override
  String get locServiceOffTitle => 'Location is off';

  @override
  String get locServiceOffBody => 'Location services seem to be turned off. Would you like to open settings?';

  @override
  String get locPermTitle => 'Permission needed';

  @override
  String get locPermBody => 'You need to enable location permission for the app in Settings.';

  @override
  String get actionOpen => 'Open';

  @override
  String get actionOpenSettings => 'Open Settings';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionEnable => 'Enable';

  @override
  String get errUnknown => 'Something went wrong.';

  @override
  String get permissionDeniedForever => 'Permission denied forever';

  @override
  String get familyNotSelected => 'Family is not selected.';

  @override
  String get noSession => 'No session';

  @override
  String get bannerLiveOn => 'Live location is ON.';

  @override
  String get bannerPermNeededBody => 'Location permission is required to share your live location.';

  @override
  String get bannerAutoOffBody => 'Live sharing seems to be off (no updates for a while). Turn it back on?';

  @override
  String get bannerStaleBody => 'Your last location is old. Share once to refresh.';

  @override
  String get actionDismiss => 'Dismiss';

  @override
  String get actionTurnOn => 'Turn On';

  @override
  String get actionStop => 'Stop';

  @override
  String get actionShareNow => 'Share now';

  @override
  String get bannerStoppedBody => 'Live sharing is turned off.';

  @override
  String get lastSeenUnknown => 'last seen: unknown';

  @override
  String get lastSeenJustNow => 'last seen: just now';

  @override
  String lastSeenMinutes(Object mins) {
    return 'last seen: $mins min ago';
  }

  @override
  String lastSeenHours(Object hours) {
    return 'last seen: $hours h ago';
  }

  @override
  String lastSeenDays(Object days) {
    return 'last seen: $days d ago';
  }

  @override
  String get chipAgoNow => 'just now';

  @override
  String chipAgoMinutes(Object mins) {
    return '${mins}m ago';
  }

  @override
  String chipAgoHours(Object hours) {
    return '${hours}h ago';
  }

  @override
  String chipAgoDays(Object days) {
    return '${days}d ago';
  }

  @override
  String get chipNever => 'never';

  @override
  String get menuMapTab => 'Family Locations';

  @override
  String get actionFitAll => 'Fit all';

  @override
  String get actionStartSharing => 'Start Sharing';

  @override
  String get actionStopSharing => 'Stop Sharing';
}

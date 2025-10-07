// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Togetherly';

  @override
  String get welcome => 'Hoş geldiniz';

  @override
  String get tasks => 'Görevler';

  @override
  String get items => 'Ürünler';

  @override
  String get expenses => 'Harcamalar';

  @override
  String get weekly => 'Haftalık';

  @override
  String get members => 'Üyeler';

  @override
  String get leaderboard => 'Liderlik Tablosu';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get welcomeBack => 'Tekrar hoş geldiniz';

  @override
  String get addMember => 'Üye ekle';

  @override
  String get pickMember => 'Devam etmek için bir üye seçin';

  @override
  String get searchMember => 'Üye ara…';

  @override
  String get noMembersFound => 'Üye bulunamadı';

  @override
  String seeAllMembers(Object count) {
    return 'Tüm üyeleri gör ($count)';
  }

  @override
  String get goToDashboard => 'Panoya git';

  @override
  String get setupFamily => 'Hadi ailenizi oluşturalım';

  @override
  String get setupFamilyDesc => 'Görevleri ve alışveriş listelerini paylaşmaya başlamak için ilk aile üyenizi ekleyin.';

  @override
  String get addFirstMember => 'İlk üyeyi ekle';

  @override
  String get setupFamilyHint => 'Her zaman sağ üstten yeni üye ekleyebilirsiniz.';

  @override
  String get allMembers => 'Tüm üyeler';

  @override
  String get showLess => 'Daha az göster';

  @override
  String get showAll => 'Tümünü göster';

  @override
  String showAllCount(int count) {
    return 'Tümünü göster ($count)';
  }

  @override
  String get category => 'Kategori';

  @override
  String get price => 'Fiyat';

  @override
  String get itemBoughtToast => '🎉 Ürün alındı!';

  @override
  String get configTitle => 'Ayarlar';

  @override
  String get configSubtitle => 'Tema, hatırlatıcılar ve aile filtrelerini özelleştirin.';

  @override
  String get familyInviteCode => 'Aile Davet Kodu';

  @override
  String get appearance => 'Görünüm';

  @override
  String get language => 'Dil';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get appColor => 'Uygulama rengi';

  @override
  String get templates => 'Şablonlar';

  @override
  String get templatesSubtitle => 'Tek dokunuşla görev ve market paketleri';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get requestPermission => 'İzin iste';

  @override
  String get permissionRequested => 'Gerekirse izin istendi';

  @override
  String get preciseAlarmsTooltip => 'Kesin alarmlara izin vermek için sistem ayarını aç';

  @override
  String get androidOnly => 'Bu ayar yalnızca Android içindir';

  @override
  String get enableExactAlarms => 'Kesin alarmları etkinleştir';

  @override
  String get couldNotOpenSettings => 'Ayarlar açılamadı';

  @override
  String get menuManageFamily => 'Aileyi yönet';

  @override
  String get menuAddCenter => 'Ekleme Merkezi';

  @override
  String get dismiss => 'KAPAT';

  @override
  String get market => 'Market';

  @override
  String get pendingToday => 'Bugün bekleyen';

  @override
  String get toBuy => 'Alınacak';

  @override
  String get totalRecords => 'Toplam kayıt';

  @override
  String get pendingTasks => 'Bekleyen görevler';

  @override
  String get myTasks => 'Görevlerim';

  @override
  String get unassigned => 'Atanmamış';

  @override
  String get itemsHeader => 'Ürünler';

  @override
  String get edit => 'Düzenle';

  @override
  String get editTask => 'Görevi düzenle';

  @override
  String get taskName => 'Görev adı';

  @override
  String get editItem => 'Ürünü düzenle';

  @override
  String get itemName => 'Ürün adı';

  @override
  String get mine => 'Benim';

  @override
  String get noData => 'Veri yok';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get assignTask => 'Görevi ata';

  @override
  String get assignItem => 'Ürünü ata';

  @override
  String get assignTo => 'Kime ata';

  @override
  String get noOne => 'Kimse';

  @override
  String get searchTasks => 'Görevlerde ara…';

  @override
  String get searchItems => 'Ürünlerde ara…';

  @override
  String get filterByAssignee => 'Atanana göre filtrele';

  @override
  String get pendingLabel => 'Bekleyen';

  @override
  String get allLabel => 'Tümü';

  @override
  String get noTasks => 'Görev yok';

  @override
  String get clearCompleted => 'Bitenleri temizle';

  @override
  String get completedTasksCleared => 'Tamamlanan görevler temizlendi';

  @override
  String get markAllDone => 'Hepsini tamamla';

  @override
  String get rename => 'Yeniden adlandır';

  @override
  String get assign => 'Ata';

  @override
  String get delete => 'Sil';

  @override
  String get editDueReminder => 'Düzenle (vade/hatırlatma)';

  @override
  String get noItems => 'Ürün yok';

  @override
  String get clearBought => 'Hepsini temizle';

  @override
  String get boughtItemsCleared => 'Alınan ürünler temizlendi';

  @override
  String get markAllBought => 'Hepsini alındı işaretle';

  @override
  String get memberFallback => 'Üye';

  @override
  String pendingCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bekleyen ($count)',
      one: 'Bekleyen (1)',
      zero: 'Bekleyen',
    );
    return '$_temp0';
  }

  @override
  String completedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tamamlanan ($count)',
      one: 'Tamamlanan (1)',
      zero: 'Tamamlanan',
    );
    return '$_temp0';
  }

  @override
  String toBuyCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alınacak ($count)',
      one: 'Alınacak (1)',
      zero: 'Alınacak',
    );
    return '$_temp0';
  }

  @override
  String boughtCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alındı ($count)',
      one: 'Alındı (1)',
      zero: 'Alındı',
    );
    return '$_temp0';
  }

  @override
  String get completedLabel => 'Tamamlanan';

  @override
  String get boughtLabel => 'Alındı';

  @override
  String get addTaskBtn => 'Görev ekle';

  @override
  String get addItemBtn => 'Ürün ekle';

  @override
  String addTaskFor(String name) {
    return '$name için görev ekle';
  }

  @override
  String addItemFor(String name) {
    return '$name için ürün ekle';
  }

  @override
  String get enterTasksHint => 'Görevleri girin (virgül veya yeni satır)…';

  @override
  String get tasksHelperExample => 'Örnek: Çamaşır, Bulaşık, Çöpü çıkar';

  @override
  String get enterItemsHint => 'Ürünleri girin (virgül veya yeni satır)…';

  @override
  String get itemsHelperExample => 'Örnek: Süt, Ekmek, Yumurta';

  @override
  String get suggestionsTitle => 'Öneriler';

  @override
  String get addTypedList => 'Yazılan listeyi ekle';

  @override
  String get itemDeleted => 'Ürün silindi';

  @override
  String get addSelected => 'Seçileni ekle';

  @override
  String addSelectedCount(int count) {
    return 'Seçileni ekle ($count)';
  }

  @override
  String addedTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count görev eklendi',
      one: '1 görev eklendi',
    );
    return '$_temp0';
  }

  @override
  String addedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ürün eklendi',
      one: '1 ürün eklendi',
    );
    return '$_temp0';
  }

  @override
  String get clearedUndo => 'Temizlendi – Geri al';

  @override
  String get undo => 'Geri al';

  @override
  String get setDueDate => 'Vade tarihi seç';

  @override
  String get setReminder => 'Hatırlatma ayarla';

  @override
  String get clear => 'Temizle';

  @override
  String duePrefix(String date) {
    return 'Vade: $date';
  }

  @override
  String remindPrefix(String date) {
    return 'Hatırlat: $date';
  }

  @override
  String get taskDeleted => 'Görev silindi';

  @override
  String get more => 'Daha fazla';

  @override
  String get taskCompletedToast => '🎉 Görev tamamlandı!';

  @override
  String pointsAwarded(int points) {
    return '➕ +$points puan';
  }

  @override
  String get thisMonth => 'Bu ay';

  @override
  String get lastMonth => 'Geçen ay';

  @override
  String get noExpenses => 'Gider yok';

  @override
  String get deleteExpenseTitle => 'Gider silinsin mi?';

  @override
  String deleteExpenseBody(String title) {
    return '“$title” kaldırılacak. Hemen ardından geri alabilirsiniz.';
  }

  @override
  String get expenseDeleted => 'Gider silindi';

  @override
  String deleteFailed(String error) {
    return 'Silme başarısız: $error';
  }

  @override
  String get addExpense => 'Gider ekle';

  @override
  String get insights => 'Analizler';

  @override
  String get otherCategory => 'Diğer';

  @override
  String expensesInsightsTitleHint(Object expenses, Object insights) {
    return 'Compose with: $expenses — $insights';
  }

  @override
  String get memberLabel => 'Üye';

  @override
  String get byCategory => 'Kategoriye göre';

  @override
  String get export => 'Dışa aktar';

  @override
  String get share => 'Paylaş';

  @override
  String get transactions => 'Hareketler';

  @override
  String recordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kayıt',
      one: '1 kayıt',
    );
    return '$_temp0';
  }

  @override
  String get exportCsvTooltip => 'CSV dışa aktar';

  @override
  String get shareTooltip => 'Paylaş';

  @override
  String get noExpensesForRange => 'Seçilen aralık için gider yok.';

  @override
  String savedCsvWithName(String name) {
    return 'CSV kaydedildi: $name';
  }

  @override
  String exportFailed(String error) {
    return 'Dışa aktarılamadı: $error';
  }

  @override
  String shareFailed(String error) {
    return 'Paylaşım başarısız: $error';
  }

  @override
  String get changeCategory => 'Kategoriyi değiştir';

  @override
  String get uncategorized => 'Kategorisiz';

  @override
  String get customCategory => 'Özel kategori';

  @override
  String get csvDate => 'tarih';

  @override
  String get csvTitle => 'başlık';

  @override
  String get csvAmount => 'tutar';

  @override
  String get csvMember => 'üye';

  @override
  String get csvCategory => 'kategori';

  @override
  String get expensesCsvShareText => 'Togetherly — Giderler CSV';

  @override
  String get categoryGroceries => 'Market';

  @override
  String get categoryDining => 'Yeme-İçme';

  @override
  String get categoryClothing => 'Giyim';

  @override
  String get categoryTransport => 'Ulaşım';

  @override
  String get categoryUtilities => 'Faturalar';

  @override
  String get categoryHealth => 'Sağlık';

  @override
  String get categoryKids => 'Çocuklar';

  @override
  String get categoryHome => 'Ev';

  @override
  String get categoryOther => 'Diğer';

  @override
  String get monthShortJan => 'O';

  @override
  String get monthShortFeb => 'Ş';

  @override
  String get monthShortMar => 'M';

  @override
  String get monthShortApr => 'N';

  @override
  String get monthShortMay => 'M';

  @override
  String get monthShortJun => 'H';

  @override
  String get monthShortJul => 'T';

  @override
  String get monthShortAug => 'A';

  @override
  String get monthShortSep => 'E';

  @override
  String get monthShortOct => 'E';

  @override
  String get monthShortNov => 'K';

  @override
  String get monthShortDec => 'A';

  @override
  String get expensesByCategoryTitle => 'Giderler — Kategori Bazında';

  @override
  String get breakdown => 'Dağılım';

  @override
  String get trend => 'Trend';

  @override
  String get member => 'Üye';

  @override
  String get totalsByCategory => 'Kategori toplamları';

  @override
  String get editBudgetTooltip => 'Bütçeyi düzenle';

  @override
  String budgetDialogTitle(String category) {
    return 'Bütçe — $category';
  }

  @override
  String get monthlyBudgetLabel => 'Aylık bütçe';

  @override
  String get monthlyBudgetHint => 'örn. 250';

  @override
  String get remove => 'Kaldır';

  @override
  String budgetUpdatedFor(String category) {
    return '$category için bütçe güncellendi';
  }

  @override
  String get last6MonthsByCategory => 'Son 6 ay (kategori bazında)';

  @override
  String get noDataLastMonths => 'Son aylar için veri yok.';

  @override
  String categoryTitle(String category) {
    return 'Kategori — $category';
  }

  @override
  String get budgetsMenu => 'Bütçeler…';

  @override
  String inviteCodeCopied(String code) {
    return 'Davet kodu kopyalandı: $code';
  }

  @override
  String get ownerLabel => 'Sahip';

  @override
  String get editMember => 'Üyeyi düzenle';

  @override
  String get changePhoto => 'Fotoğrafı değiştir';

  @override
  String get removePhoto => 'Fotoğrafı kaldır';

  @override
  String get removeUser => 'Üyeyi kaldır';

  @override
  String photoUpdateFailed(String error) {
    return 'Fotoğraf güncellenemedi: $error';
  }

  @override
  String removeFailed(String error) {
    return 'Kaldırılamadı: $error';
  }

  @override
  String get memberRemoved => 'Üye kaldırıldı';

  @override
  String get removeMemberTitle => 'Üye kaldırılsın mı?';

  @override
  String removeMemberBody(String name) {
    return '“$name” bu aileden kaldırılacak.';
  }

  @override
  String get inviteMember => 'Üye davet et';

  @override
  String get shareInviteCode => 'Ailenizin davet kodunu paylaşın';

  @override
  String get copyCode => 'Kodu kopyala';

  @override
  String get copyAndShare => 'Kopyala ve Paylaş';

  @override
  String get inviteCode => 'Davet kodu';

  @override
  String get noFamilyMembersYet => 'Henüz aile üyesi yok';

  @override
  String get useInviteCodeHint => 'Üye eklemek için yukarıdaki davet kodunu kullanın.';

  @override
  String get editMemberLabel => 'Üye etiketini düzenle';

  @override
  String get label => 'Etiket';

  @override
  String get setupYourFamily => 'Aileni ayarla';

  @override
  String get createFamilyTab => 'Aile oluştur';

  @override
  String get joinWithCodeTab => 'Kodla katıl';

  @override
  String get chooseFamilyName => 'Bir aile adı seç';

  @override
  String get familyNameLabel => 'Aile adı';

  @override
  String get familyNameHint => 'örn. Dostlar Ailesi';

  @override
  String get nameCheckingOk => 'Harika! Bu isim uygun.';

  @override
  String get nameCheckingTaken => 'Bu isim kullanımda. Şunları deneyin:';

  @override
  String get createFamilyCta => 'Aile oluştur';

  @override
  String get joinExistingFamily => 'Mevcut bir aileye katıl';

  @override
  String get inviteCodeLabel => 'Davet kodu';

  @override
  String get inviteCodeHint => 'örn. ABCD23';

  @override
  String get paste => 'Yapıştır';

  @override
  String get joinFamilyCta => 'Aileye katıl';

  @override
  String get errorFamilyNameEmpty => 'Aile adı boş olamaz';

  @override
  String get errorNameUnavailable => 'Bu isim şu an kullanılamıyor';

  @override
  String get errorInviteEmpty => 'Davet kodu boş olamaz';

  @override
  String get errorInviteInvalid => 'Geçersiz davet kodu';

  @override
  String get inviteYourFamily => 'Aileni davet et';

  @override
  String get inviteShareHelp => 'Evinize katılmaları için bu kodu ailenizle paylaşın.';

  @override
  String get copy => 'Kopyala';

  @override
  String get done => 'Bitti';

  @override
  String inviteShareText(String code) {
    return 'Togetherly\'de ailemize katıl: $code';
  }

  @override
  String get weeklyTaskPlanTitle => 'Haftalık Görev Planı';

  @override
  String get weeklyTaskPlanSubtitle => 'Haftalık rutinleri planlayın ve ailenize atayın.';

  @override
  String get defaultTime => 'Varsayılan saat';

  @override
  String addToDayShort(String day) {
    return '$day gününe ekle';
  }

  @override
  String get noWeeklyTasks => 'Henüz görev yok';

  @override
  String addTaskForDay(String day) {
    return '$day için görev ekle';
  }

  @override
  String get enterTaskHint => 'Görev girin…';

  @override
  String get assignToOptional => 'Atanacak kişi (opsiyonel)';

  @override
  String addedToDay(String day) {
    return '$day gününe eklendi';
  }

  @override
  String addedToDayAndSynced(String day) {
    return '$day gününe eklendi ve Görevler\'e senkronlandı';
  }

  @override
  String get defaultWeeklyReminderSaved => 'Varsayılan haftalık hatırlatma saati kaydedildi';

  @override
  String get onLabel => 'Açık';

  @override
  String get offLabel => 'Kapalı';

  @override
  String get disableNotifications => 'Bildirimleri kapat';

  @override
  String get enableNotifications => 'Bildirimleri aç';

  @override
  String get notificationsEnabled => 'Bildirimler açıldı';

  @override
  String get notificationsDisabled => 'Bildirimler kapandı';

  @override
  String get setTime => 'Saat ayarla';

  @override
  String get clearTime => 'Saati temizle';

  @override
  String get reminderUpdated => 'Hatırlatıcı güncellendi';

  @override
  String get reminderTimeCleared => 'Hatırlatıcı saati temizlendi';

  @override
  String get editWeeklyTask => 'Haftalık görevi düzenle';

  @override
  String get dayLabel => 'Gün';

  @override
  String get assignToLabel => 'Kime ata';

  @override
  String get reminderTime => 'Hatırlatma saati';

  @override
  String get notSet => 'Ayarlı değil';

  @override
  String get notificationsLabel => 'Bildirimler';

  @override
  String get weeklyTaskUpdated => 'Haftalık görev güncellendi';

  @override
  String get weekdayShortMon => 'Pzt';

  @override
  String get weekdayShortTue => 'Sal';

  @override
  String get weekdayShortWed => 'Çar';

  @override
  String get weekdayShortThu => 'Per';

  @override
  String get weekdayShortFri => 'Cum';

  @override
  String get weekdayShortSat => 'Cts';

  @override
  String get weekdayShortSun => 'Paz';

  @override
  String get weekdayMonday => 'Pazartesi';

  @override
  String get weekdayTuesday => 'Salı';

  @override
  String get weekdayWednesday => 'Çarşamba';

  @override
  String get weekdayThursday => 'Perşembe';

  @override
  String get weekdayFriday => 'Cuma';

  @override
  String get weekdaySaturday => 'Cumartesi';

  @override
  String get weekdaySunday => 'Pazar';

  @override
  String get editExpense => 'Harcamayı düzenle';

  @override
  String get titleLabel => 'Başlık';

  @override
  String get amountLabel => 'Tutar';

  @override
  String get newCategory => 'Yeni kategori';

  @override
  String get nameLabel => 'Ad';

  @override
  String get recentLabel => 'Son kullanılan';

  @override
  String get titleRequired => 'Başlık gerekli';

  @override
  String get enterValidAmount => 'Geçerli bir tutar girin';

  @override
  String get amountGreaterThanZero => 'Tutar 0\'dan büyük olmalı';

  @override
  String addedAmount(String amount) {
    return '$amount eklendi';
  }

  @override
  String updatedAmount(String amount) {
    return '$amount güncellendi';
  }

  @override
  String saveFailedWithError(String error) {
    return 'Kaydetme hatası: $error';
  }

  @override
  String get noActiveFamily => 'Aktif aile yok';

  @override
  String get add => 'Ekle';

  @override
  String get week => 'Hafta';

  @override
  String get today => 'Bugün';

  @override
  String get month => 'Ay';

  @override
  String get quickAddTitle => 'Hızlı Ekle';

  @override
  String get quickAddSubtitle => 'Yeni görevleri ve market öğelerini tek yerden ekleyin.';

  @override
  String get allTasksHeader => 'Tüm görevler';

  @override
  String get allItemsHeader => 'Tüm öğeler';

  @override
  String get enterTaskHintShort => 'Görev yazın…';

  @override
  String get enterItemHintShort => 'Öğe yazın…';

  @override
  String get taskAlreadyExists => 'Bu görev zaten var';

  @override
  String get itemAlreadyExists => 'Bu öğe zaten var';

  @override
  String get taskAddedToast => 'Görev eklendi';

  @override
  String get itemAddedToast => 'Öğe eklendi';

  @override
  String get editNameTitle => 'Adı düzenle';

  @override
  String get assignTooltip => 'Ata';

  @override
  String get editTooltip => 'Düzenle';

  @override
  String get taskTakeOutTrash => 'Çöpü çıkar';

  @override
  String get taskCleanKitchen => 'Mutfağı temizle';

  @override
  String get taskDoLaundry => 'Çamaşır yıka';

  @override
  String get taskVacuumLiving => 'Salon süpür';

  @override
  String get taskWashDishes => 'Bulaşıkları yıka';

  @override
  String get taskWaterPlants => 'Bitkileri sula';

  @override
  String get taskCookDinner => 'Akşam yemeği yap';

  @override
  String get taskOrganizeFridge => 'Buzdolabını düzenle';

  @override
  String get taskChangeBedsheets => 'Nevresim değiştir';

  @override
  String get taskIronClothes => 'Kıyafetleri ütüle';

  @override
  String get itemMilk => 'Süt';

  @override
  String get itemBread => 'Ekmek';

  @override
  String get itemEggs => 'Yumurta';

  @override
  String get itemButter => 'Tereyağı';

  @override
  String get itemCheese => 'Peynir';

  @override
  String get itemRice => 'Pirinç';

  @override
  String get itemPasta => 'Makarna';

  @override
  String get itemTomatoes => 'Domates';

  @override
  String get itemPotatoes => 'Patates';

  @override
  String get itemOnions => 'Soğan';

  @override
  String get itemApples => 'Elma';

  @override
  String get itemBananas => 'Muz';

  @override
  String get itemChicken => 'Tavuk';

  @override
  String get itemBeef => 'Dana eti';

  @override
  String get itemFish => 'Balık';

  @override
  String get itemOliveOil => 'Zeytinyağı';

  @override
  String get itemSalt => 'Tuz';

  @override
  String get itemSugar => 'Şeker';

  @override
  String get itemCoffee => 'Kahve';

  @override
  String get itemTea => 'Çay';

  @override
  String get cannotAffectOthersScores => 'Başka üyenin puanını değiştirme izniniz yok.';

  @override
  String get actionNotAllowed => 'Bu işlem için izniniz yok.';

  @override
  String get somethingWentWrong => 'Bir şeyler ters gitti.';

  @override
  String get editorLabel => 'Editör';

  @override
  String get viewerLabel => 'İzleyici';

  @override
  String get roleUpdated => 'Rol güncellendi.';

  @override
  String updateFailed(Object error) {
    return 'Güncelleme başarısız: $error';
  }

  @override
  String get signIn => 'Giriş yap';

  @override
  String get retry => 'Yeniden dene';
}

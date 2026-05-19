class AppStrings {
  final String appSubtitle;
  final String shareAppText;

  // Home
  final String selectGame;
  final String classicOkey;
  final String joinLive;
  final String screenOnHint;
  final String joinLiveTitle;
  final String join;

  // Onboarding
  final String welcomeTitle;
  final String welcomeSubtitle;
  final String yourName;
  final String start;
  final String noDataNeeded;

  // Profile
  final String profile;
  final String pastGames;
  final String viewHistory;
  final String appearance;
  final String darkTheme;
  final String lightTheme;
  final String girlsMode;
  final String language;
  final String premiumTitle;
  final String premiumSubtitle;
  final String premiumCta;
  final String nameHint;
  final String idCopied;

  // Score
  final String endGame;
  final String liveTable;
  final String noRoundsYet;
  final String total;
  final String roundPrefix;
  final String penalty;
  final String siler;
  final String penaltyHint;
  final String silerHint;
  final String addPenalty;
  final String addSiler;
  final String addRound;
  final String cancel;
  final String undo;
  final String undoTitle;
  final String undoContent;
  final String endGameTitle;
  final String endGameContent;
  final String gameSummaryTitle;
  final String shareImage;
  final String backToHome;
  final String ratingQuestion;
  final String ratingSubtext;
  final String later;
  final String rate;
  final String save;
  final String roundResultClassic;
  final String roundResultOkey101;
  final String winnerLabel;
  final String finishScore;
  final String gosterge;
  final String preview;

  // Live
  final String liveActive;
  final String roomCodeLabel;
  final String shareRoomCode;
  final String stopLive;
  final String liveDescription;
  final String startLive;
  final String roomPrefix;
  final String leave;

  // Round limit
  final String roundLimitTitle;
  final String roundLimitContent;
  final String roundLimitYes;
  final String roundLimitNo;

  // Complaint
  final String complaintSection;
  final String complaintTitle;
  final String complaintSubtitle;
  final String complaintSend;
  final String complaintSuccess;
  final List<String> complaintHints;

  // History
  final String gameHistoryTitle;
  final String clearHistoryTooltip;
  final String clearHistoryTitle;
  final String clearHistoryContent;
  final String delete;
  final String noGamesYet;
  final String noGamesYetSub;
  final String justNow;
  final String yesterday;
  final String pairedSuffix;
  final String soloSuffix;

  // Setup
  final String gameMode;
  final String soloMode;
  final String pairedMode;
  final String teamNamesLabel;
  final String playerNamesLabel;
  final String totalRoundsLabel;
  final String roundsHint;
  final String startGame;
  final String defaultTeamA;
  final String defaultTeamB;

  // Dice
  final String diceTitle;
  final String rolling;
  final String tapToRoll;
  final String rollAgain;

  // Chat
  final String chatTitle;
  final String clearChat;
  final String chatHint;
  final List<String> okey101Questions;
  final List<String> classicOkeyQuestions;
  final List<String> mixedQuestions;

  // Private helper fragments
  final String _wonSuffix;
  final String _roundsPlayedSuffix;
  final String _minutesAgoSuffix;
  final String _hoursAgoSuffix;
  final List<String> _playerHints;
  final List<String> _teamHints;
  final String _defaultPlayer;

  const AppStrings._({
    required this.appSubtitle,
    required this.shareAppText,
    required this.selectGame,
    required this.classicOkey,
    required this.joinLive,
    required this.screenOnHint,
    required this.joinLiveTitle,
    required this.join,
    required this.welcomeTitle,
    required this.welcomeSubtitle,
    required this.yourName,
    required this.start,
    required this.noDataNeeded,
    required this.profile,
    required this.pastGames,
    required this.viewHistory,
    required this.appearance,
    required this.darkTheme,
    required this.lightTheme,
    required this.girlsMode,
    required this.language,
    required this.premiumTitle,
    required this.premiumSubtitle,
    required this.premiumCta,
    required this.nameHint,
    required this.idCopied,
    required this.endGame,
    required this.liveTable,
    required this.noRoundsYet,
    required this.total,
    required this.roundPrefix,
    required this.penalty,
    required this.siler,
    required this.penaltyHint,
    required this.silerHint,
    required this.addPenalty,
    required this.addSiler,
    required this.addRound,
    required this.cancel,
    required this.undo,
    required this.undoTitle,
    required this.undoContent,
    required this.endGameTitle,
    required this.endGameContent,
    required this.gameSummaryTitle,
    required this.shareImage,
    required this.backToHome,
    required this.ratingQuestion,
    required this.ratingSubtext,
    required this.later,
    required this.rate,
    required this.save,
    required this.roundResultClassic,
    required this.roundResultOkey101,
    required this.winnerLabel,
    required this.finishScore,
    required this.gosterge,
    required this.preview,
    required this.liveActive,
    required this.roomCodeLabel,
    required this.shareRoomCode,
    required this.stopLive,
    required this.liveDescription,
    required this.startLive,
    required this.roomPrefix,
    required this.leave,
    required this.roundLimitTitle,
    required this.roundLimitContent,
    required this.roundLimitYes,
    required this.roundLimitNo,
    required this.complaintSection,
    required this.complaintTitle,
    required this.complaintSubtitle,
    required this.complaintSend,
    required this.complaintSuccess,
    required this.complaintHints,
    required this.gameHistoryTitle,
    required this.clearHistoryTooltip,
    required this.clearHistoryTitle,
    required this.clearHistoryContent,
    required this.delete,
    required this.noGamesYet,
    required this.noGamesYetSub,
    required this.justNow,
    required this.yesterday,
    required this.pairedSuffix,
    required this.soloSuffix,
    required this.gameMode,
    required this.soloMode,
    required this.pairedMode,
    required this.teamNamesLabel,
    required this.playerNamesLabel,
    required this.totalRoundsLabel,
    required this.roundsHint,
    required this.startGame,
    required this.defaultTeamA,
    required this.defaultTeamB,
    required this.diceTitle,
    required this.rolling,
    required this.tapToRoll,
    required this.rollAgain,
    required this.chatTitle,
    required this.clearChat,
    required this.chatHint,
    required this.okey101Questions,
    required this.classicOkeyQuestions,
    required this.mixedQuestions,
    required String wonSuffix,
    required String roundsPlayedSuffix,
    required String minutesAgoSuffix,
    required String hoursAgoSuffix,
    required List<String> playerHints,
    required List<String> teamHints,
    required String defaultPlayer,
  })  : _wonSuffix = wonSuffix,
        _roundsPlayedSuffix = roundsPlayedSuffix,
        _minutesAgoSuffix = minutesAgoSuffix,
        _hoursAgoSuffix = hoursAgoSuffix,
        _playerHints = playerHints,
        _teamHints = teamHints,
        _defaultPlayer = defaultPlayer;

  String won(String name) => '$name $_wonSuffix';
  String roundsPlayedText(int n) => '$n $_roundsPlayedSuffix';
  String roundLabel(int n, [int? ofTotal]) =>
      ofTotal != null ? '$roundPrefix $n / $ofTotal' : '$roundPrefix $n';
  String minutesAgoText(int n) => '$n $_minutesAgoSuffix';
  String hoursAgoText(int n) => '$n $_hoursAgoSuffix';
  String defaultPlayerName(int index) => '$_defaultPlayer ${index + 1}';
  List<String> get playerHints => _playerHints;
  List<String> get teamHints => _teamHints;

  static const tr = AppStrings._(
    appSubtitle: 'Masa çevresinde skor & kural asistanı',
    shareAppText:
        'Okey masasında skor & kural asistanı — Okeymatik! https://okeymatik.app',
    selectGame: 'OYUN SEÇİN',
    classicOkey: 'Klasik Okey',
    joinLive: 'Canlı Masaya Katıl',
    screenOnHint: 'Ekran sürekli açık kalır · Düşük pil tüketimi',
    joinLiveTitle: 'Canlı Masaya Katıl',
    join: 'Katıl',
    welcomeTitle: "Okeymatik'e Hoş Geldin",
    welcomeSubtitle: 'Seni nasıl çağıralım?',
    yourName: 'Adın',
    start: 'Başla',
    noDataNeeded: 'Telefon numarası veya e-posta gerekmez.',
    profile: 'Profil',
    pastGames: 'Geçmiş Oyunlar',
    viewHistory: 'Oyun Geçmişini Görüntüle',
    appearance: 'Görünüm',
    darkTheme: 'Koyu',
    lightTheme: 'Açık',
    girlsMode: 'Girls Mode',
    language: 'Dil',
    premiumTitle: 'Premium Üyelik',
    premiumSubtitle: 'Aylık ₺20 — Reklamlarsız deneyim',
    premiumCta: 'Başla',
    nameHint: 'Ad gir...',
    idCopied: 'ID kopyalandı',
    endGame: 'Bitir',
    liveTable: 'Canlı Masa',
    noRoundsYet: 'Henüz el girilmedi',
    total: 'Toplam',
    roundPrefix: 'El',
    penalty: 'Ceza',
    siler: 'Siler',
    penaltyHint: 'Ceza puanı ekle (pozitif)',
    silerHint: 'Siler puanı (otomatik eksi)',
    addPenalty: 'Ceza Ekle',
    addSiler: 'Siler Ekle',
    addRound: 'El Ekle',
    cancel: 'İptal',
    undo: 'Geri Al',
    undoTitle: 'Son eli geri al?',
    undoContent: 'Son elin skorları silinecek.',
    endGameTitle: 'Oyunu bitir?',
    endGameContent: 'Skorlar kaydedilmeyecek.',
    gameSummaryTitle: 'Oyun Bitti',
    shareImage: 'Görseli Paylaş',
    backToHome: 'Ana Menüye Dön',
    ratingQuestion: "Okeymatik'ten keyif alıyor musunuz?",
    ratingSubtext: 'Değerlendirmeniz uygulamanın büyümesine yardımcı olur.',
    later: 'Daha Sonra',
    rate: 'Değerlendir ⭐',
    save: 'Kaydet',
    roundResultClassic: 'El Sonucu — Klasik Okey',
    roundResultOkey101: 'El Sonucu — Okey 101',
    winnerLabel: 'Biten',
    finishScore: 'Bitiş Puanı',
    gosterge: 'Gösterge taşı gösterildi (+1 ceza diğerlerine)',
    preview: 'Önizleme',
    liveActive: 'Canlı Yayında',
    roomCodeLabel: 'Oda Kodu',
    shareRoomCode: 'Bu kodu arkadaşlarınla paylaş',
    stopLive: 'Canlı Yayını Durdur',
    liveDescription:
        'Skorları arkadaşlarınla gerçek zamanlı paylaş. Bir oda kodu oluşturulur, arkadaşların bu kodla takip edebilir.',
    startLive: 'Canlı Masa Başlat',
    roomPrefix: 'Oda:',
    leave: 'Ayrıl',
    roundLimitTitle: 'Hedef Ele Ulaşıldı!',
    roundLimitContent: 'Belirlenen el sayısına ulaşıldı. Oyunu bitirmek ister misiniz?',
    roundLimitYes: 'Evet, Bitir',
    roundLimitNo: 'Hayır, Devam Et',
    complaintSection: 'Destek',
    complaintTitle: 'Şikayetim Var',
    complaintSubtitle: 'Hızlıca bildir, birlikte geliştirelim',
    complaintSend: 'Gönder',
    complaintSuccess: 'Geri bildiriminiz alındı 🙏',
    complaintHints: [
      'Skor yanlış hesaplandı',
      'AI yanlış cevap verdi',
      'Oda sistemi çalışmadı',
      'Ekran dondu veya takıldı',
      'Puan kaydedilmedi',
    ],
    gameHistoryTitle: 'Oyun Geçmişi',
    clearHistoryTooltip: 'Geçmişi temizle',
    clearHistoryTitle: 'Geçmişi sil?',
    clearHistoryContent: 'Tüm oyun geçmişi silinecek.',
    delete: 'Sil',
    noGamesYet: 'Henüz oyun yok',
    noGamesYetSub: 'Oyun bitirince burada görünür',
    justNow: 'Az önce',
    yesterday: 'Dün',
    pairedSuffix: 'Eşli',
    soloSuffix: 'Tekli',
    gameMode: 'Oyun Modu',
    soloMode: 'Tekli',
    pairedMode: 'Eşli (2v2)',
    teamNamesLabel: 'Takım İsimleri',
    playerNamesLabel: 'Oyuncu İsimleri',
    totalRoundsLabel: 'Tur Sayısı (isteğe bağlı)',
    roundsHint: 'Boş bırakılabilir',
    startGame: 'Oyunu Başlat',
    defaultTeamA: 'Takım A',
    defaultTeamB: 'Takım B',
    diceTitle: 'Zar At',
    rolling: 'Atılıyor...',
    tapToRoll: 'Zara dokunarak at',
    rollAgain: 'Tekrar At',
    chatTitle: 'Kural Asistanı',
    clearChat: 'Sohbeti temizle',
    chatHint: 'Kural sorun...',
    okey101Questions: [
      '101 siler kaç puan düşürüyor?',
      'El açmayan kaç ceza alır?',
      'Okey atarak bitiş ne olur?',
      'Islek taş cezası nedir?',
      'Elden bitiş kaç ceza?',
      'Eşli modda partner ceza siliyor mu?',
    ],
    classicOkeyQuestions: [
      'Normal bitiş kaç puan?',
      'Okey ile bitiş kaç puan?',
      'Çiftten bitiş kaç puan?',
      'Gösterge nedir?',
      'Okey ve çiftten kaç puan?',
      'Okey ıskat nedir?',
    ],
    mixedQuestions: [
      'Normal bitiş kaç puan?',
      '101 siler kaç düşer?',
      'El açmayan kaç ceza alır?',
      'Okey ile bitince ne olur?',
      'Çiftten bitiş kaç puan?',
      'Islek taş cezası nedir?',
    ],
    wonSuffix: 'Kazandı!',
    roundsPlayedSuffix: 'el oynandı',
    minutesAgoSuffix: 'dk önce',
    hoursAgoSuffix: 'saat önce',
    playerHints: ['Oyuncu 1', 'Oyuncu 2', 'Oyuncu 3', 'Oyuncu 4'],
    teamHints: ['Takım A', 'Takım B'],
    defaultPlayer: 'Oyuncu',
  );

  static const en = AppStrings._(
    appSubtitle: 'Score tracker & rules assistant for Okey',
    shareAppText:
        'Score & rules assistant for Okey — Okeymatik! https://okeymatik.app',
    selectGame: 'SELECT GAME',
    classicOkey: 'Classic Okey',
    joinLive: 'Join Live Table',
    screenOnHint: 'Screen stays on · Low battery usage',
    joinLiveTitle: 'Join Live Table',
    join: 'Join',
    welcomeTitle: 'Welcome to Okeymatik',
    welcomeSubtitle: 'What should we call you?',
    yourName: 'Your name',
    start: 'Get Started',
    noDataNeeded: 'No phone number or email needed.',
    profile: 'Profile',
    pastGames: 'Past Games',
    viewHistory: 'View Game History',
    appearance: 'Appearance',
    darkTheme: 'Dark',
    lightTheme: 'Light',
    girlsMode: 'Girls Mode',
    language: 'Language',
    premiumTitle: 'Premium Membership',
    premiumSubtitle: '₺20 / month — Ad-free experience',
    premiumCta: 'Start',
    nameHint: 'Enter name...',
    idCopied: 'ID copied',
    endGame: 'End',
    liveTable: 'Live Table',
    noRoundsYet: 'No rounds yet',
    total: 'Total',
    roundPrefix: 'Rnd',
    penalty: 'Penalty',
    siler: 'Siler',
    penaltyHint: 'Add penalty points (positive)',
    silerHint: 'Siler points (auto minus)',
    addPenalty: 'Add Penalty',
    addSiler: 'Add Siler',
    addRound: 'Add Round',
    cancel: 'Cancel',
    undo: 'Undo',
    undoTitle: 'Undo last round?',
    undoContent: 'The last round will be removed.',
    endGameTitle: 'End game?',
    endGameContent: 'Scores will not be saved.',
    gameSummaryTitle: 'Game Over',
    shareImage: 'Share Image',
    backToHome: 'Back to Home',
    ratingQuestion: 'Enjoying Okeymatik?',
    ratingSubtext: 'Your rating helps the app grow.',
    later: 'Maybe Later',
    rate: 'Rate ⭐',
    save: 'Save',
    roundResultClassic: 'Round Result — Classic Okey',
    roundResultOkey101: 'Round Result — Okey 101',
    winnerLabel: 'Finished',
    finishScore: 'Finish Score',
    gosterge: 'Indicator shown (+1 penalty to others)',
    preview: 'Preview',
    liveActive: 'Live',
    roomCodeLabel: 'Room Code',
    shareRoomCode: 'Share this code with friends',
    stopLive: 'Stop Live',
    liveDescription:
        'Share scores with friends in real time. A room code will be created for others to follow.',
    startLive: 'Start Live Table',
    roomPrefix: 'Room:',
    leave: 'Leave',
    roundLimitTitle: 'Target Reached!',
    roundLimitContent: 'You\'ve played the set number of rounds. Would you like to end the game?',
    roundLimitYes: 'Yes, End Game',
    roundLimitNo: 'No, Continue',
    complaintSection: 'Support',
    complaintTitle: 'Report an Issue',
    complaintSubtitle: 'Quick feedback, we\'ll improve',
    complaintSend: 'Send',
    complaintSuccess: 'Your report was received 🙏',
    complaintHints: [
      'Score was calculated wrong',
      'AI gave a wrong answer',
      'Room system didn\'t work',
      'Screen froze or lagged',
      'Score was not saved',
    ],
    gameHistoryTitle: 'Game History',
    clearHistoryTooltip: 'Clear history',
    clearHistoryTitle: 'Clear history?',
    clearHistoryContent: 'All game history will be deleted.',
    delete: 'Delete',
    noGamesYet: 'No games yet',
    noGamesYetSub: 'Finished games will appear here',
    justNow: 'Just now',
    yesterday: 'Yesterday',
    pairedSuffix: 'Paired',
    soloSuffix: 'Solo',
    gameMode: 'Game Mode',
    soloMode: 'Solo',
    pairedMode: 'Paired (2v2)',
    teamNamesLabel: 'Team Names',
    playerNamesLabel: 'Player Names',
    totalRoundsLabel: 'Rounds (optional)',
    roundsHint: 'Leave blank',
    startGame: 'Start Game',
    defaultTeamA: 'Team A',
    defaultTeamB: 'Team B',
    diceTitle: 'Roll Dice',
    rolling: 'Rolling...',
    tapToRoll: 'Tap to roll',
    rollAgain: 'Roll Again',
    chatTitle: 'Rules Assistant',
    clearChat: 'Clear chat',
    chatHint: 'Ask a rule...',
    okey101Questions: [
      'How many points does 101 siler reduce?',
      'Penalty for not opening a hand?',
      'What happens finishing by discarding Okey?',
      'What is the wet tile penalty?',
      'Penalty for finishing from hand?',
      'Does partner cancel penalty in paired mode?',
    ],
    classicOkeyQuestions: [
      'Points for a normal finish?',
      'Points for finishing with Okey?',
      'Points for a double finish?',
      'What is the indicator tile?',
      'Points for Okey + double finish?',
      'What is Okey discard penalty?',
    ],
    mixedQuestions: [
      'Points for a normal finish?',
      'How many does 101 siler reduce?',
      'Penalty for not opening a hand?',
      'What happens finishing with Okey?',
      'Points for a double finish?',
      'What is the wet tile penalty?',
    ],
    wonSuffix: 'Won!',
    roundsPlayedSuffix: 'rounds played',
    minutesAgoSuffix: 'm ago',
    hoursAgoSuffix: 'h ago',
    playerHints: ['Player 1', 'Player 2', 'Player 3', 'Player 4'],
    teamHints: ['Team A', 'Team B'],
    defaultPlayer: 'Player',
  );
}

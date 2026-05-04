enum GameType { classicOkey, okey101 }

enum GameMode { solo, paired }

enum ClassicFinishType {
  normal,           // 2 puan
  okeyIle,          // 4 puan
  ciftten,          // 4 puan (7 çift)
  okeyIleCiftten,   // 8 puan
}

enum Okey101FinishType {
  normal,     // siler: -101
  okeyAtarak, // siler: -202, others x2
  elden,      // siler: -202, others: 404
  eldenOkey,  // siler: -404, others: 808
}

extension ClassicFinishTypeLabel on ClassicFinishType {
  String get label {
    switch (this) {
      case ClassicFinishType.normal:
        return 'Normal (2p)';
      case ClassicFinishType.okeyIle:
        return 'Okey ile (4p)';
      case ClassicFinishType.ciftten:
        return 'Çiftten (4p)';
      case ClassicFinishType.okeyIleCiftten:
        return 'Okey+Çift (8p)';
    }
  }

  int get penalty {
    switch (this) {
      case ClassicFinishType.normal:
        return 2;
      case ClassicFinishType.okeyIle:
        return 4;
      case ClassicFinishType.ciftten:
        return 4;
      case ClassicFinishType.okeyIleCiftten:
        return 8;
    }
  }
}

extension Okey101FinishTypeLabel on Okey101FinishType {
  String get label {
    switch (this) {
      case Okey101FinishType.normal:
        return 'Normal (-101)';
      case Okey101FinishType.okeyAtarak:
        return 'Okey Atarak (-202)';
      case Okey101FinishType.elden:
        return 'Elden (-202)';
      case Okey101FinishType.eldenOkey:
        return 'Elden+Okey (-404)';
    }
  }
}

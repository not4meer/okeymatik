enum GameType { classicOkey, okey101 }

enum GameMode { solo, paired }

enum ClassicFinishType {
  normal,           // winner -2, others +2
  okeyIle,          // winner -4, others +4
  elden,            // winner -4, others +4
  ciftten,          // winner -4, others +4
  eldenOkey,        // winner -6, others +6
  okeyIleCiftten,   // winner -8, others +8
}

enum Okey101FinishType {
  normal,        // siler: -101,  el açmış: ×1,  el açmamış: +202
  okeyAtarak,    // siler: -202,  el açmış: ×2,  el açmamış: +404
  elden,         // siler: -202,  el açmış: ×2,  el açmamış: +404
  eldenOkey,     // siler: -404,  el açmış: ×4,  el açmamış: +808
  ciftBitis,     // siler: -202,  el açmış: ×2,  el açmamış: +404
  ciftOkeyBitis, // siler: -404,  el açmış: ×4,  el açmamış: +808
}

extension ClassicFinishTypeLabel on ClassicFinishType {
  String get label {
    switch (this) {
      case ClassicFinishType.normal:
        return 'Normal (-2/+2)';
      case ClassicFinishType.okeyIle:
        return 'Okey ile (-4/+4)';
      case ClassicFinishType.elden:
        return 'Elden (-4/+4)';
      case ClassicFinishType.ciftten:
        return 'Çiftten (-4/+4)';
      case ClassicFinishType.eldenOkey:
        return 'Elden+Okey (-6/+6)';
      case ClassicFinishType.okeyIleCiftten:
        return 'Okey+Çift (-8/+8)';
    }
  }

  int get penalty {
    switch (this) {
      case ClassicFinishType.normal:
        return 2;
      case ClassicFinishType.okeyIle:
        return 4;
      case ClassicFinishType.elden:
        return 4;
      case ClassicFinishType.ciftten:
        return 4;
      case ClassicFinishType.eldenOkey:
        return 6;
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
      case Okey101FinishType.ciftBitis:
        return 'Çift Bitiş (-202)';
      case Okey101FinishType.ciftOkeyBitis:
        return 'Çift+Okey (-404)';
    }
  }
}

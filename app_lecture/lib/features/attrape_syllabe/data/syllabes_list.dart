class SyllabesData {
  /// Syllabes simples avec voyelles (a, e, i, o, u, y)
  static const List<String> niveau1 = [
    'pa', 'pe', 'pi', 'po', 'pu',
    'ma', 'me', 'mi', 'mo', 'mu',
    'ta', 'te', 'ti', 'to', 'tu',
    'la', 'le', 'li', 'lo', 'lu',
    'ra', 're', 'ri', 'ro', 'ru',
    'sa', 'se', 'si', 'so', 'su',
    'fa', 'fe', 'fi', 'fo', 'fu',
    'va', 've', 'vi', 'vo', 'vu',
    'na', 'ne', 'ni', 'no', 'nu',
    'da', 'de', 'di', 'do', 'du',
    'ba', 'be', 'bi', 'bo', 'bu',
  ];

  /// Sons composés (ou, on, an, in, oi, au, eau, ch)
  static const List<String> niveau2 = [
    // ou
    'pou', 'mou', 'tou', 'lou', 'rou', 'sou', 'fou', 'vou', 'nou', 'dou', 'bou',
    // on
    'pon', 'mon', 'ton', 'lon', 'ron', 'son', 'fon', 'von', 'non', 'don', 'bon',
    // an / en
    'pan', 'man', 'tan', 'lan', 'ran', 'san', 'fan', 'van', 'nan', 'dan', 'ban',
    'pen', 'men', 'ten', 'len', 'ren', 'sen', 'fen', 'ven', 'nen', 'den', 'ben',
    // in
    'pin', 'min', 'tin', 'lin', 'rin', 'sin', 'fin', 'vin', 'nin', 'din', 'bin',
    // oi
    'poi', 'moi', 'toi', 'loi', 'roi', 'soi', 'foi', 'voi', 'noi', 'doi', 'boi',
    // ch
    'cha', 'che', 'chi', 'cho', 'chu', 'chou', 'chon', 'chan',
  ];

  /// Consonnes doubles (br, cr, dr, fr, gr, pr, tr, vr, bl, cl, fl, gl, pl)
  static const List<String> niveau3 = [
    'bra', 'bre', 'bri', 'bro', 'bru', 'brou',
    'cra', 'cre', 'cri', 'cro', 'cru', 'crou',
    'dra', 'dre', 'dri', 'dro', 'dru', 'drou',
    'fra', 'fre', 'fri', 'fro', 'fru', 'frou',
    'gra', 'gre', 'gri', 'gro', 'gru', 'grou',
    'pra', 'pre', 'pri', 'pro', 'pru', 'prou',
    'tra', 'tre', 'tri', 'tro', 'tru', 'trou',
    'bla', 'ble', 'bli', 'blo', 'blu', 'blou',
    'cla', 'cle', 'cli', 'clo', 'clu', 'clou',
    'fla', 'fle', 'fli', 'flo', 'flu', 'flou',
    'pla', 'ple', 'pli', 'plo', 'plu', 'plou',
  ];

  /// Syllabes inverses et complexes (ar, er, ir, or, ur, eil, euil, ouil)
  static const List<String> niveau4 = [
    'ar', 'er', 'ir', 'or', 'ur',
    'al', 'el', 'il', 'ol', 'ul',
    'as', 'es', 'is', 'os', 'us',
    'ac', 'ec', 'ic', 'oc', 'uc',
    'eil', 'euil', 'ouil', 'ail',
    'gnon', 'gna', 'gno',
    'tion', 'sion',
  ];

  static List<String> getSyllabesForLevel(int level) {
    switch (level) {
      case 1:
        return niveau1;
      case 2:
        return niveau2;
      case 3:
        return niveau3;
      case 4:
        return niveau4;
      default:
        return niveau1;
    }
  }

  /// Retourne N syllabes aléatoires incluant la cible pour ce niveau
  static List<String> getRandomSyllables({
    required int level, 
    required String targetSyllable, 
    required int count
  }) {
    final List<String> available = getSyllabesForLevel(level).toList();
    available.remove(targetSyllable);
    
    available.shuffle();
    final List<String> result = [targetSyllable];
    
    for (int i = 0; i < count - 1; i++) {
        if (i < available.length) {
          result.add(available[i]);
        }
    }
    
    result.shuffle();
    return result;
  }
}

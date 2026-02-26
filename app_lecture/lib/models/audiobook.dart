class AudiobookPage {
  final String imagePath;
  final int startTimeSeconds; // when the page should be shown

  AudiobookPage({
    required this.imagePath,
    required this.startTimeSeconds,
  });
}

class Audiobook {
  final String title;
  final String coverPath;
  final String audioPath;
  final List<AudiobookPage> pages;

  Audiobook({
    required this.title,
    required this.coverPath,
    required this.audioPath,
    required this.pages,
  });
}

// Default configuration for Le Petit Poucet
final Audiobook petitPoucetAudiobook = Audiobook(
  title: "Le Petit Poucet",
  coverPath: "assets/audiobook/couverture.png",
  audioPath: "audiobook/ElevenLabs_CHARLES_PERRAULT-Le_petit_poucet.mp3",
  pages: [
    // Note: The audio path is relative to the "assets/" folder when using audioplayers, so 'audiobook/Eleven...'
    AudiobookPage(imagePath: "assets/audiobook/planche_1.png", startTimeSeconds: 0),
    AudiobookPage(imagePath: "assets/audiobook/planche_2.png", startTimeSeconds: 30),
    AudiobookPage(imagePath: "assets/audiobook/planche_3.png", startTimeSeconds: 60),
    AudiobookPage(imagePath: "assets/audiobook/planche_4.png", startTimeSeconds: 90),
    AudiobookPage(imagePath: "assets/audiobook/planche_5.png", startTimeSeconds: 120),
    AudiobookPage(imagePath: "assets/audiobook/planche_6.png", startTimeSeconds: 150),
    AudiobookPage(imagePath: "assets/audiobook/planche_7.png", startTimeSeconds: 180),
    AudiobookPage(imagePath: "assets/audiobook/planche_8.png", startTimeSeconds: 210),
    AudiobookPage(imagePath: "assets/audiobook/planche_9.png", startTimeSeconds: 240),
    AudiobookPage(imagePath: "assets/audiobook/planche_10.png", startTimeSeconds: 270),
    AudiobookPage(imagePath: "assets/audiobook/planche_11.png", startTimeSeconds: 300),
  ],
);

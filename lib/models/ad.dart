/// Model representing an advertisement
class Ad {
  final int id;
  final String filePath;
  final String link;
  final String mediaType;

  Ad({
    required this.id,
    required this.filePath,
    required this.link,
    required this.mediaType,
  });

  factory Ad.fromJson(Map<String, dynamic> j) => Ad(
        id: j['id'],
        filePath: j['file_path'],
        link: j['link'],
        mediaType: j['media_type'],
      );
}


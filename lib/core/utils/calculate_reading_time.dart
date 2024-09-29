int calculateReadingTime(String content) {
  const readingSpeed = 225;
  final wordCount = content.split(RegExp(r"\s+")).length;
  return (wordCount / readingSpeed).ceil();
}

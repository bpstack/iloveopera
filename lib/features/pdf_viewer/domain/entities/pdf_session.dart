/// Lightweight reference to an open PDF document in a session.
///
/// Holds identifying metadata (name, page count) and the resolved page
/// metadata. The actual document bytes/lifecycle live in the data layer.
class PdfSession {
  const PdfSession({
    required this.sourceName,
    required this.pageCount,
    required this.pages,
  });

  final String sourceName;
  final int pageCount;
  final List<PdfPageInfo> pages;

  PdfPageInfo pageAt(int oneBasedPageNumber) {
    assert(oneBasedPageNumber >= 1 && oneBasedPageNumber <= pageCount);
    return pages[oneBasedPageNumber - 1];
  }
}

class PdfPageInfo {
  const PdfPageInfo({
    required this.pageNumber,
    required this.widthPoints,
    required this.heightPoints,
  });

  final int pageNumber;
  final double widthPoints;
  final double heightPoints;
}

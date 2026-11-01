import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neo_reader/data/parsers/epub_parser.dart';

List<int> _epubBytes({required bool withNav, required bool withNcx}) {
  final archive = Archive();

  void add(String name, String content) {
    final data = utf8.encode(content);
    archive.addFile(ArchiveFile(name, data.length, data));
  }

  add(
    'mimetype',
    'application/epub+zip',
  );
  add(
    'META-INF/container.xml',
    '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''',
  );

  final items = StringBuffer()
    ..writeln(
      '<item id="c1" href="chap1.xhtml" media-type="application/xhtml+xml"/>',
    )
    ..writeln(
      '<item id="c2" href="chap2.xhtml" media-type="application/xhtml+xml"/>',
    );
  if (withNav) {
    items.writeln(
      '<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>',
    );
  }
  if (withNcx) {
    items.writeln(
      '<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>',
    );
  }

  add(
    'OEBPS/content.opf',
    '''<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="uid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Sample</dc:title>
    <dc:creator>Tester</dc:creator>
    <dc:identifier id="uid">demo</dc:identifier>
  </metadata>
  <manifest>
    ${items.toString()}
  </manifest>
  <spine${withNcx ? ' toc="ncx"' : ''}>
    <itemref idref="c1"/>
    <itemref idref="c2"/>
  </spine>
</package>''',
  );

  add(
    'OEBPS/chap1.xhtml',
    '''<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml"><body><h1>H1 One</h1><p>Hello one.</p></body></html>''',
  );
  add(
    'OEBPS/chap2.xhtml',
    '''<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml"><body><p>Hello two without heading.</p></body></html>''',
  );

  if (withNav) {
    add(
      'OEBPS/nav.xhtml',
      '''<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <ol>
        <li><a href="chap1.xhtml">Nav Chapter One</a></li>
        <li><a href="chap2.xhtml">Nav Chapter Two</a></li>
      </ol>
    </nav>
  </body>
</html>''',
    );
  }
  if (withNcx) {
    add(
      'OEBPS/toc.ncx',
      '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="np1"><navLabel><text>NCX One</text></navLabel><content src="chap1.xhtml"/></navPoint>
    <navPoint id="np2"><navLabel><text>NCX Two</text></navLabel><content src="chap2.xhtml"/></navPoint>
  </navMap>
</ncx>''',
    );
  }

  return ZipEncoder().encode(archive)!;
}

void main() {
  test('prefers EPUB3 nav titles and aligns spine', () {
    final data = EpubParser().parseBytes(_epubBytes(withNav: true, withNcx: true));
    expect(data.chapters, hasLength(2));
    expect(data.chapters[0].title, 'Nav Chapter One');
    expect(data.chapters[1].title, 'Nav Chapter Two');
    expect(data.toc, hasLength(2));
    expect(data.toc[0].spineIndex, 0);
    expect(data.toc[1].spineIndex, 1);
  });

  test('falls back to NCX when nav missing', () {
    final data = EpubParser().parseBytes(_epubBytes(withNav: false, withNcx: true));
    expect(data.chapters[0].title, 'NCX One');
    expect(data.chapters[1].title, 'NCX Two');
    expect(data.effectiveToc.first.title, 'NCX One');
  });

  test('uses heading then numbered fallback without toc', () {
    final data = EpubParser().parseBytes(_epubBytes(withNav: false, withNcx: false));
    expect(data.chapters[0].title, 'H1 One');
    expect(data.chapters[1].title, '第2章');
  });
}

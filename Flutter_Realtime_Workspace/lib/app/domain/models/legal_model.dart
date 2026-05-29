/// A single section within a legal document (ToS or Privacy Policy).
class LegalSection {
  final String id;
  final String heading;
  final String body;
  final List<String> items;
  final String? footer;
  final List<LegalSubsection> subsections;

  const LegalSection({
    required this.id,
    required this.heading,
    required this.body,
    this.items = const [],
    this.footer,
    this.subsections = const [],
  });

    factory LegalSection.fromJson(Map<String, dynamic> json) {
    final resolvedHeading =
      (json['heading'] ?? json['title'] ?? '').toString().trim();
    final resolvedBody =
      (json['body'] ?? json['content'] ?? '').toString().trim();

    return LegalSection(
      id: (json['id'] ?? json['_id'] ?? resolvedHeading).toString(),
      heading: resolvedHeading,
      body: resolvedBody,
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        footer: json['footer'] as String?,
        subsections: (json['subsections'] as List<dynamic>?)
                ?.map((e) => LegalSubsection.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
    }
}

/// A subsection within a legal section (e.g., 2.1, 2.2).
class LegalSubsection {
  final String heading;
  final List<String> items;

  const LegalSubsection({required this.heading, this.items = const []});

  factory LegalSubsection.fromJson(Map<String, dynamic> json) {
    return LegalSubsection(
        heading: (json['heading'] ?? json['title'] ?? '').toString(),
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
  }
}

/// A complete legal document (Terms of Service or Privacy Policy).
class LegalDocument {
  final String title;
  final String effectiveDate;
  final String lastUpdated;
  final String version;
  final List<LegalSection> sections;

  const LegalDocument({
    required this.title,
    required this.effectiveDate,
    required this.lastUpdated,
    required this.version,
    required this.sections,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    final sections = <LegalSection>[];

    if (rawSections is List) {
      for (final section in rawSections) {
        if (section is Map<String, dynamic>) {
          sections.add(LegalSection.fromJson(section));
        }
      }
    }

    return LegalDocument(
      title: (json['title'] ?? 'Legal Document').toString(),
      effectiveDate: (json['effectiveDate'] ?? '').toString(),
      lastUpdated: (json['lastUpdated'] ?? '').toString(),
      version: (json['version'] ?? '1.0.0').toString(),
      sections: sections,
    );
  }
}

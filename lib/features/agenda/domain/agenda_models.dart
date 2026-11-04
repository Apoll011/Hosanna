/// Parsed responsibility entry from an agenda event's JSON blob.
class AgendaResponsibility {
  const AgendaResponsibility({
    required this.id,
    required this.categoryId,
    required this.assignees,
  });

  final String id;
  final String categoryId;
  final List<AgendaAssignee> assignees;

  static List<AgendaResponsibility> parse(Object? raw) {
    if (raw is! List) return const [];
    final out = <AgendaResponsibility>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final assigneesRaw = map['assignees'];
      final assignees = <AgendaAssignee>[];
      if (assigneesRaw is List) {
        for (final a in assigneesRaw) {
          if (a is! Map) continue;
          final am = Map<String, dynamic>.from(a);
          final name = (am['name'] as String?)?.trim() ?? '';
          if (name.isEmpty) continue;
          assignees.add(
            AgendaAssignee(
              id: (am['id'] as String?) ?? '',
              name: name,
              avatarUrl: am['avatarUrl'] as String?,
            ),
          );
        }
      }
      out.add(
        AgendaResponsibility(
          id: (map['id'] as String?) ?? '',
          categoryId: (map['categoryId'] as String?) ?? '',
          assignees: assignees,
        ),
      );
    }
    return out;
  }
}

class AgendaAssignee {
  const AgendaAssignee({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? avatarUrl;
}

/// Formats an end clock from start `HH:mm` + duration minutes.
String? agendaEndTime(String start, int durationMinutes) {
  if (durationMinutes <= 0) return null;
  final parts = start.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  final total = h * 60 + m + durationMinutes;
  final eh = (total ~/ 60) % 24;
  final em = total % 60;
  return '${eh.toString().padLeft(2, '0')}:${em.toString().padLeft(2, '0')}';
}

String agendaDayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

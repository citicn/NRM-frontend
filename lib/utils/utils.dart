const String baseUrl = 'http://10.0.2.2:5000/uploads';

String getUserStatus(String? lastSeenIso) {
  if (lastSeenIso == null || lastSeenIso.isEmpty) return "Nepoznat";
  try {
    final lastSeen = DateTime.parse(lastSeenIso);
    final now = DateTime.now().toUtc();
    if (now.difference(lastSeen).inMinutes < 2) {
      return "Online";
    } else {
      return "Offline";
    }
  } catch (e) {
    return "Nepoznat";
  }
}

String getFullImageUrl(String? fileName) {
  if (fileName == null || fileName.isEmpty) {
    return 'https://img.freepik.com/premium-vector/man-avatar-profile-picture-isolated-background-avatar-profile-picture-man_1293239-4841.jpg?semt=ais_hybrid&w=740';
  }

  return '$baseUrl/$fileName';
}


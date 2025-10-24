class TimeFormatter {
  static String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) {
      return 'Offline';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 5) {
      return 'Active now';
    } else if (difference.inMinutes < 60) {
      return 'Active ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Active ${hours}h ago';
    } else if (difference.inDays == 1) {
      return 'Active yesterday';
    } else if (difference.inDays < 7) {
      return 'Active ${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Active ${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Active ${months}mo ago';
    } else {
      return 'Offline';
    }
  }

  static String formatOnlineStatus(DateTime? lastSeen) {
    if (lastSeen == null) {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 5) {
      return 'Online now';
    } else if (difference.inMinutes < 60) {
      return 'Online ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Online ${hours}h ago';
    } else {
      return 'Offline';
    }
  }
}
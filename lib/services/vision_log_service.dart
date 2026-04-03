import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Model for a single Vision feature usage log entry
class VisionLog {
  final String id;
  final String featureName;
  final DateTime usedAt;
  final String? imageUrl;
  final String? aiOutput;

  VisionLog({
    required this.id,
    required this.featureName,
    required this.usedAt,
    this.imageUrl,
    this.aiOutput,
  });

  factory VisionLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VisionLog(
      id: doc.id,
      featureName: data['featureName'] as String? ?? 'Unknown',
      usedAt: (data['usedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'] as String?,
      aiOutput: data['aiOutput'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'featureName': featureName,
      'usedAt': Timestamp.fromDate(usedAt),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (aiOutput != null) 'aiOutput': aiOutput,
    };
  }
}

/// Service for reading and writing vision logs to Firestore
/// Collection path: users/{uid}/visionLogs
class VisionLogService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>? _collection() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('visionLogs');
  }

  /// Stream ordered by newest first
  Stream<List<VisionLog>> logsStream() {
    final col = _collection();
    if (col == null) return Stream.value([]);
    return col
        .orderBy('usedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(VisionLog.fromFirestore).toList());
  }

  /// Add a new log entry
  Future<void> addLog({
    required String featureName,
    String? imageUrl,
    String? aiOutput,
  }) async {
    final col = _collection();
    if (col == null) return;
    await col.add(VisionLog(
      id: '',
      featureName: featureName,
      usedAt: DateTime.now(),
      imageUrl: imageUrl,
      aiOutput: aiOutput,
    ).toFirestore());
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum FriendStatus { none, pendingSent, pendingReceived, friends }

class FriendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUid => _auth.currentUser!.uid;

  Future<void> sendFriendRequest(String toUserId) async {
    await _db.collection('friend_requests').add({
      'fromUserId': _currentUid,
      'toUserId': toUserId,
      'status': 'pending',
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptFriendRequest({
    required String requestId,
    required String fromUserId,
  }) async {
    final batch = _db.batch();

    batch.delete(_db.collection('friend_requests').doc(requestId));

    batch.set(_db.collection('friendships').doc(), {
      'userAId': fromUserId,
      'userBId': _currentUid,
      'friendsSince': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> declineFriendRequest(String requestId) async {
    await _db.collection('friend_requests').doc(requestId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getIncomingRequests() {
    // Single-field filter only — avoids composite index requirement.
    // Status filtering is done client-side in the UI.
    return _db
        .collection('friend_requests')
        .where('toUserId', isEqualTo: _currentUid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getFriends() {
    return _db
        .collection('friendships')
        .where(
          Filter.or(
            Filter('userAId', isEqualTo: _currentUid),
            Filter('userBId', isEqualTo: _currentUid),
          ),
        )
        .snapshots();
  }

  Future<FriendStatus> getFriendStatus(String otherUserId) async {
    final friendshipSnap = await _db
        .collection('friendships')
        .where(
          Filter.or(
            Filter.and(
              Filter('userAId', isEqualTo: _currentUid),
              Filter('userBId', isEqualTo: otherUserId),
            ),
            Filter.and(
              Filter('userAId', isEqualTo: otherUserId),
              Filter('userBId', isEqualTo: _currentUid),
            ),
          ),
        )
        .limit(1)
        .get();

    if (friendshipSnap.docs.isNotEmpty) return FriendStatus.friends;

    final sentSnap = await _db
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: _currentUid)
        .where('toUserId', isEqualTo: otherUserId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (sentSnap.docs.isNotEmpty) return FriendStatus.pendingSent;

    final receivedSnap = await _db
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: otherUserId)
        .where('toUserId', isEqualTo: _currentUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (receivedSnap.docs.isNotEmpty) return FriendStatus.pendingReceived;

    return FriendStatus.none;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getSharedMatches(
      String friendId) {
    return _db
        .collection('matches')
        .where(
          Filter.or(
            Filter.and(
              Filter('userAId', isEqualTo: _currentUid),
              Filter('userBId', isEqualTo: friendId),
            ),
            Filter.and(
              Filter('userAId', isEqualTo: friendId),
              Filter('userBId', isEqualTo: _currentUid),
            ),
          ),
        )
        .orderBy('matchedAt', descending: true)
        .snapshots();
  }
}

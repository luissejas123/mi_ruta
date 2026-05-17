import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/user/data/datasources/user_remote_datasource.dart';
import 'package:mi_ruta/features/user/data/models/user_model.dart';

/// Implementación de UserRemoteDataSource - Conexión real a Firestore
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore _firestore;

  UserRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserModel> getCurrentUser() async {
    // TODO: Implementar con Firebase Auth
    throw UnimplementedError('getCurrentUser no implementado');
  }

  @override
  Future<UserModel> getUserById(String uid) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Usuario no encontrado');
      }

      return UserModel.fromJson(docSnapshot.data() ?? {});
    } catch (e) {
      throw Exception('Error obteniendo usuario: $e');
    }
  }

  @override
  Future<List<UserModel>> getUsersByIds(List<String> uids) async {
    try {
      if (uids.isEmpty) return [];

      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: uids)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo usuarios: $e');
    }
  }

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore
          .collection('users')
          .doc(uid)
          .update(data);
    } catch (e) {
      throw Exception('Error actualizando usuario: $e');
    }
  }

  @override
  Future<double> getUserRating(String uid) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!docSnapshot.exists) return 0.0;

      return (docSnapshot.data()?['rating'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('Error obteniendo calificación: $e');
    }
  }

  @override
  Stream<UserModel> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Usuario no encontrado');
      }
      return UserModel.fromJson(snapshot.data() ?? {});
    });
  }
}

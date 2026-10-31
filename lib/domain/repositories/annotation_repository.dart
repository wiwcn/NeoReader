import '../models/annotation.dart';

abstract class AnnotationRepository {
  Future<List<Annotation>> forBook(String bookId);
  Future<List<Annotation>> all();
  Future<void> add(Annotation annotation);
  Future<void> delete(String id);
}

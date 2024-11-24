import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/blog/domain/entities/blog.dart';
import 'package:oshmobile/features/blog/domain/repositories/blog_repository.dart';

class GetAllBlogs implements UseCase<List<Blog>, NoParams> {
  final BlogRepository blogRepository;

  GetAllBlogs({required this.blogRepository});

  @override
  Future<Either<Failure, List<Blog>>> call(NoParams params) async {
    return blogRepository.getAllBlogs();
  }
}

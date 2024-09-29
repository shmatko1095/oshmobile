part of 'blog_bloc.dart';

@immutable
sealed class BlogState {
  const BlogState();
}

final class BlogInitial extends BlogState {}

final class BlogLoading extends BlogState {
  const BlogLoading();
}

final class BlogFailure extends BlogState {
  final String error;

  const BlogFailure({required this.error});
}

final class BlogUploadSuccess extends BlogState {}

final class BlogFetchSuccess extends BlogState {
  final List<Blog> blogs;

  const BlogFetchSuccess({required this.blogs});
}

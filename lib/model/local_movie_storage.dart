import 'package:get_storage/get_storage.dart';
import 'package:release_schedule/model/movie.dart';

class LocalMovieStorage {
  List<MovieData> _storedMovies = [];
  update(List<MovieData> movies) {
    _storedMovies = movies;
  }

  Future<List<MovieData>> retrieve() async {
    return _storedMovies;
  }
}

class LocalMovieStorageGetStorage extends LocalMovieStorage {
  Future<void>? initialized;
  GetStorage? container;
  MovieData Function(Map jsonEncodable) toMovieData;

  LocalMovieStorageGetStorage(this.toMovieData) {
    initialized = _init();
  }
  _init() async {
    await GetStorage.init("movies");
    container = GetStorage("movies");
  }

  @override
  update(List<MovieData> movies) async {
    await initialized;
    container!.write(
        "movies", movies.map((movie) => movie.toJsonEncodable()).toList());
  }

  @override
  Future<List<MovieData>> retrieve() async {
    await initialized;
    dynamic movies = container!.read("movies");
    if (movies == null) {
      return [];
    }
    return (movies as List<dynamic>)
        .map((encodable) => toMovieData(encodable))
        .toList();
  }
}

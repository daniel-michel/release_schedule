import 'package:flutter/material.dart';
import 'package:release_schedule/api/wikidata/wikidata_movie.dart';
import 'package:release_schedule/api/wikidata/wikidata_movie_api.dart';
import 'package:release_schedule/model/dates.dart';
import 'package:release_schedule/model/live_search.dart';
import 'package:release_schedule/model/local_movie_storage.dart';
import 'package:release_schedule/model/movie_manager.dart';
import 'package:release_schedule/view/movie_item.dart';
import 'package:release_schedule/view/movie_manager_list.dart';

void main() {
  runApp(const MyApp());
}

final MovieManager _globalMovieManager = MovieManager(
  WikidataMovieApi(),
  LocalMovieStorageGetStorage(WikidataMovieData.fromEncodable),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Schedule',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: HomePage(_globalMovieManager),
    );
  }
}

class HomePage extends StatefulWidget {
  final MovieManager manager;

  const HomePage(this.manager, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late LiveSearch liveSearch;
  late TextEditingController _searchController;
  late PageController _pageController;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _pageController = PageController(initialPage: 1);
    liveSearch = LiveSearch(widget.manager);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _setSearchResultsVisibility(bool visible) {
    int newPage = visible ? 0 : 1;
    if (currentPage == newPage) {
      return;
    }
    currentPage = newPage;
    setState(() {
      _pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: "Search",
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  liveSearch.updateSearch(value);
                  _setSearchResultsVisibility(value.isNotEmpty);
                },
              ),
            ),
            liveSearch.searchTerm.isEmpty
                ? Container()
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      liveSearch.updateSearch("");
                      _setSearchResultsVisibility(false);
                    },
                  ),
          ],
        ),
        actions: [HamburgerMenu(widget.manager)],
      ),
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          SearchResultPage(
            liveSearch: liveSearch,
            manager: widget.manager,
          ),
          OverviewPage(manager: widget.manager),
        ],
      ),
    );
  }
}

class SearchResultPage extends StatelessWidget {
  const SearchResultPage({
    super.key,
    required this.liveSearch,
    required this.manager,
  });

  final LiveSearch liveSearch;
  final MovieManager manager;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: liveSearch,
      builder: (context, child) {
        return Column(
          children: [
            liveSearch.loading ? const LinearProgressIndicator() : Container(),
            Expanded(
              child: ListView.builder(
                itemCount: liveSearch.searchResults.length,
                itemBuilder: (context, index) => MovieItem(
                  movie: liveSearch.searchResults[index],
                  manager: manager,
                  showReleaseDate: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class OverviewPage extends StatelessWidget {
  const OverviewPage({
    super.key,
    required this.manager,
  });

  final MovieManager manager;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list), child: Text("Upcoming")),
              Tab(icon: Icon(Icons.bookmark), child: Text("Bookmarked")),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                Scaffold(
                  body: MovieManagerList(
                    manager,
                    // Only show movies that are bookmarked or have a release date with at least month precision and at least one title
                    filter: (movie) =>
                        movie.bookmarked ||
                        (movie.releaseDate != null &&
                            movie.releaseDate!.precision >=
                                DatePrecision.month &&
                            movie.title != null),
                  ),
                  floatingActionButton: FloatingActionButton(
                    child: const Icon(Icons.refresh),
                    onPressed: () async {
                      var scaffold = ScaffoldMessenger.of(context);
                      try {
                        await manager.loadUpcomingMovies();
                      } catch (e) {
                        scaffold.showSnackBar(
                          const SnackBar(
                            content: Text("Failed to load upcoming movies"),
                          ),
                        );
                        rethrow;
                      }
                    },
                  ),
                ),
                MovieManagerList(
                  manager,
                  filter: (movie) => movie.bookmarked,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HamburgerMenu extends StatelessWidget {
  final MovieManager manager;
  const HamburgerMenu(this.manager, {super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.menu),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            child: const Text("Remove irrelevant"),
            onTap: () => manager.removeMoviesWhere((movie) =>
                !movie.bookmarked &&
                !(movie.releaseDates?.value?.any((date) =>
                        date.precision >= DatePrecision.month &&
                        date.date.isAfter(DateTime.now()
                            .subtract(const Duration(days: 30)))) ??
                    false)),
          ),
          PopupMenuItem(
            child: const Text("Remove all not bookmarked"),
            onTap: () =>
                manager.removeMoviesWhere((movie) => !movie.bookmarked),
          ),
          PopupMenuItem(
            child: const Text("Remove all"),
            onTap: () => manager.removeMoviesWhere((movie) => true),
          ),
        ];
      },
    );
  }
}

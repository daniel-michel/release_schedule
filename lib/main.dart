import 'package:flutter/material.dart';
import 'package:release_schedule/model/live_search.dart';
import 'package:release_schedule/model/movie.dart';
import 'package:release_schedule/model/movie_manager.dart';
import 'package:release_schedule/view/movie_list.dart';
import 'package:release_schedule/view/movie_manager_list.dart';
import 'package:release_schedule/view/swipe-transition.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Schedule',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(movieManager),
    );
  }
}

class HomePage extends StatefulWidget {
  final MovieManager manager;

  HomePage(this.manager, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late LiveSearch liveSearch;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, // the SingleTickerProviderStateMixin
      duration: const Duration(milliseconds: 300),
    );
    liveSearch = LiveSearch(widget.manager);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: "Search",
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              if (value.isEmpty) {
                _controller.reverse();
              } else {
                _controller.forward();
              }
              liveSearch.updateSearch(value);
            });
          },
        ),
        actions: [HamburgerMenu(widget.manager)],
      ),
      body: SwipeTransition(
        animation: _controller,
        first: OverviewPage(manager: widget.manager),
        second: SearchResultPage(liveSearch: liveSearch),
      ),
    );
  }
}

class SearchResultPage extends StatelessWidget {
  const SearchResultPage({
    super.key,
    required this.liveSearch,
  });

  final LiveSearch liveSearch;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: liveSearch,
      builder: (context, child) {
        return MovieList(liveSearch.searchResults);
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
          Expanded(
            child: TabBarView(
              children: [
                Scaffold(
                  body: MovieManagerList(
                    manager,
                    // Only show movies that are bookmarked or have a release date with at least month precision and at least one title
                    filter: (movie) =>
                        movie.bookmarked ||
                        (movie.releaseDate.precision >= DatePrecision.month &&
                            (movie.titles?.length ?? 0) >= 1),
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
          const TabBar(tabs: [
            Tab(icon: Icon(Icons.list), child: Text("Upcoming")),
            Tab(icon: Icon(Icons.bookmark), child: Text("Bookmarked")),
          ]),
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
                !(movie.releaseDates?.any((date) =>
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

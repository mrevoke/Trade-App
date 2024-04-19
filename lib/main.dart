import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:trade/stock_data.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'watchlist_ui.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
     debugShowCheckedModeBanner: false,
       title: 'Trade App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WatchlistScreen(
        currentIndex: 0,
      ),
    );
  }
}

class WatchlistScreen extends StatefulWidget {
  final int currentIndex;

  const WatchlistScreen({Key? key, required this.currentIndex})
      : super(key: key);

  @override
  _WatchlistScreenState createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final channel = IOWebSocketChannel.connect(
      'ws://122.179.143.201:8089/websocket?sessionID=jeet&userID=jeet&apiToken=jeet');

  Map<String, dynamic> symbolData =
      Map.fromEntries(symbolDataall.entries.take(10));

  Map<String, dynamic> ltpData = {};
  List<int> tokens = [];
  final TextEditingController _searchController = TextEditingController();
  List<String> filteredTokens = [];

  @override
  void initState() {
    super.initState();
    symbolData = Map.fromEntries(
      symbolDataall.entries.skip(widget.currentIndex).take(10),
    );
    subscribe();
    loadHeartedStocks();
    _searchController.addListener(_onSearchChanged);
    channel.stream.listen((data) {
      setState(() {
        ltpData = jsonDecode(data);
      });
    }, onDone: () {
      print("WebSocket channel closed");
    }, onError: (error) {
      print("Error: $error");
    });
  }

  @override
  void dispose() {
    super.dispose();
    channel.sink.close();
    saveHeartedStocks();
    _searchController.dispose();
  }

  void subscribe() {
    tokens = symbolData.keys.map((key) => int.parse(key)).toList();
    Map<String, dynamic> subscribeData = {
      "Task": "subscribe",
      "Mode": "ltp",
      "Tokens": tokens
    };
    String jsonData = jsonEncode(subscribeData);
    channel.sink.add(jsonData);
  }

  void saveHeartedStocks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> heartedStocks = [];
    symbolData.forEach((key, value) {
      if (value['isFavorite']) {
        heartedStocks.add(key);
      }
    });
    await prefs.setStringList('heartedStocks', heartedStocks);
  }

  Future<void> loadHeartedStocks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? heartedStocks = prefs.getStringList('heartedStocks');
    if (heartedStocks != null) {
      setState(() {
        for (String token in heartedStocks) {
          symbolData[token]?['isFavorite'] = true;
        }
      });
    }
  }

  void unsubscribe(int token) {
    Map<String, dynamic> unsubscribeData = {
      "Task": "unsubscribe",
      "Mode": "ltp",
      "Tokens": [token]
    };
    String jsonData = jsonEncode(unsubscribeData);
    channel.sink.add(jsonData);
  }

  void removeFromWatchlist(int token) {
    setState(() {
      symbolData.remove(token.toString());
      unsubscribe(token);
      saveHeartedStocks();
    });
  }

  void toggleFavorite(int token) {
    setState(() {
      symbolData[token.toString()]["isFavorite"] =
          !symbolData[token.toString()]["isFavorite"];
      saveHeartedStocks();
    });
  }

  void _onSearchChanged() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      filteredTokens = symbolData.keys.where((token) {
        final symbolItem = symbolData[token]!;
        final symbol = symbolItem['symbol'].toLowerCase();
        final company = symbolItem['company'].toLowerCase();
        return symbol.contains(searchTerm) || company.contains(searchTerm);
      }).toList();
    });
  }

  void loadMoreItems() {
    int nextIndex = widget.currentIndex + 10;
    if (nextIndex >= symbolDataall.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more next items.'),
        ),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WatchlistScreen(currentIndex: nextIndex),
      ),
    );
  }

  void goBack() {
    int previousIndex = widget.currentIndex - 10;
    if (previousIndex >= 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WatchlistScreen(currentIndex: previousIndex),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more previous items.'),
        ),
      );
    }
  }

  bool hasNextItems() {
    return true; // Implement your logic here
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearchEmpty = _searchController.text.isEmpty;

    List<String> displayTokens =
        isSearchEmpty ? symbolData.keys.toList() : filteredTokens;

    List<String> favoriteTokens = [];
    List<String> nonFavoriteTokens = [];
    for (var token in displayTokens) {
      if (symbolData[token]!['isFavorite']) {
        favoriteTokens.add(token);
      } else {
        nonFavoriteTokens.add(token);
      }
    }

    List<String> sortedTokens = [];
    sortedTokens.addAll(favoriteTokens);
    sortedTokens.addAll(nonFavoriteTokens);

    return buildWatchlistUI(
      searchController: _searchController,
      sortedTokens: sortedTokens,
      symbolData: symbolData,
      ltpData: ltpData,
      removeFromWatchlist: removeFromWatchlist,
      toggleFavorite: toggleFavorite,
      goBack: goBack,
      hasNextItems: hasNextItems,
      loadMoreItems: loadMoreItems,
    );
  }
}

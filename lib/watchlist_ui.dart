import 'package:flutter/material.dart';

Widget buildWatchlistUI({
  required TextEditingController searchController,
  required List<String> sortedTokens,
  required Map<String, dynamic> symbolData,
  required Map<String, dynamic> ltpData,
  required Function(int) removeFromWatchlist,
  required Function(int) toggleFavorite,
  required Function() goBack,
  required bool Function() hasNextItems,
  required Function() loadMoreItems,
}) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Stocks Watchlist'),
      backgroundColor: const Color.fromARGB(255, 140, 190, 236), 
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search stocks by name...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white, 
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sortedTokens.length,
            itemBuilder: (BuildContext context, int index) {
              final token = sortedTokens[index];
              final symbolItem = symbolData[token];
              final symbol = symbolItem!['symbol'];
              final ltpItem = ltpData[token.toString()];
              final ltp = ltpItem != null ? ltpItem.toString() : 'Loading...';

              return Dismissible(
                key: Key(token),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    removeFromWatchlist(int.parse(token));
                  }
                },
                background: Container(
                  color: const Color.fromARGB(255, 176, 168, 167),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      IconButton(
                        icon: symbolItem['isFavorite']
                            ? const Icon(
                                Icons.favorite,
                                color: Color.fromARGB(255, 14, 114, 176),
                              )
                            : const Icon(
                                Icons.favorite_border,
                                color: Color.fromARGB(255, 139, 178, 188),
                              ),
                        onPressed: () {
                          toggleFavorite(int.parse(token));
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(symbol),
                      const Expanded(
                        child: SizedBox(),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      const SizedBox(
                        width: 55,
                      ),
                      Text('LTP: $ltp'),
                    ],
                  ),
                  children: [
                    ListTile(
                      title: Text('Company: ${symbolItem["company"]}'),
                    ),
                    ListTile(
                      title: Text('Industry: ${symbolItem["industry"]}'),
                    ),
                    ListTile(
                      title: Text(
                          'Sectoral Index: ${symbolItem["sectoralIndex"]}'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
    persistentFooterButtons: [
      Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: goBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 140, 190, 236), 
              ),
              child: const Text(
                'Prev',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
          const Spacer(),
          Expanded(
            child: ElevatedButton(
              onPressed: hasNextItems() ? loadMoreItems : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 140, 190, 236), 
              ),
              child: const Text(
                'Next',
                style: TextStyle(color: Colors.black), 
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

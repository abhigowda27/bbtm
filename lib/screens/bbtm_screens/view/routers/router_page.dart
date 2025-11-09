import 'package:bbtml_new/common/common_services.dart';
import 'package:bbtml_new/screens/bbtm_screens/controllers/storage.dart';
import 'package:bbtml_new/screens/bbtm_screens/models/router_model.dart';
import 'package:bbtml_new/screens/bbtm_screens/view/routers/add_router.dart';
import 'package:bbtml_new/screens/bbtm_screens/widgets/router/router_card.dart';
import 'package:bbtml_new/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class RouterPage extends StatefulWidget {
  const RouterPage({super.key});

  @override
  State<RouterPage> createState() => _RouterPageState();
}

class _RouterPageState extends State<RouterPage> {
  final StorageController _storageController = StorageController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<RouterDetails> _allRouters = [];
  List<RouterDetails> _filteredRouters = [];
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    fetchRouters();
    _scrollController.addListener(_handleScroll);
  }

  Future<void> fetchRouters() async {
    final routers = await _storageController.readRouters();
    setState(() {
      _allRouters = routers;
      _filteredRouters = routers;
    });
  }

  void _filterRouters(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredRouters = _allRouters;
      });
    } else {
      setState(() {
        _filteredRouters = _allRouters
            .where((routerDetails) =>
                routerDetails.switchName
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                routerDetails.switchID
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                routerDetails.routerName
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent) {
      if (_isFabVisible) {
        setState(() {
          _isFabVisible = false;
        });
      }
    } else {
      if (!_isFabVisible) {
        setState(() {
          _isFabVisible = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _isFabVisible
          ? FloatingActionButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30), // roundness
              ),
              child: Transform.rotate(
                angle: -90 * 3.1415926535897932 / 180,
                child: SvgPicture.asset(
                  "assets/images/wifi.svg",
                  color: Theme.of(context).appColors.background,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddNewRouterPage(
                      isFromSwitch: false,
                    ),
                  ),
                );
              },
            )
          : null,
      appBar: AppBar(
        title: const Text('ROUTERS'),
      ),
      body: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  color: Theme.of(context).appColors.primary,
                ),
                height: MediaQuery.of(context).size.height * 0.07,
              ),
              Positioned(
                bottom: -25,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).appColors.background,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterRouters,
                    decoration: const InputDecoration(
                      hintText: 'Search devices...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Expanded(
            child: _filteredRouters.isEmpty
                ? CommonServices.noDataWidget()
                : ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.all(screenWidth * 0.06),
                    itemCount: _filteredRouters.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = _filteredRouters.length - 1 - index;
                      final routerDetails = _filteredRouters[reversedIndex];
                      return RouterCard(routerDetails: routerDetails);
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const SizedBox(
                        height: 16,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

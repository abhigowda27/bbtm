import 'package:bbtml_new/blocs/switch/switch_bloc.dart';
import 'package:bbtml_new/blocs/switch/switch_event.dart';
import 'package:bbtml_new/common/api_status.dart';
import 'package:bbtml_new/common/common_services.dart';
import 'package:bbtml_new/common/common_state.dart';
import 'package:bbtml_new/screens/switches/widgets/switch_lists.dart';
import 'package:bbtml_new/theme/app_colors_extension.dart';
import 'package:bbtml_new/widgets/shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'add_switch_tab.dart';

class SwitchCloudPage extends StatefulWidget {
  const SwitchCloudPage({super.key});

  @override
  State<SwitchCloudPage> createState() => _SwitchCloudPageState();
}

class _SwitchCloudPageState extends State<SwitchCloudPage> {
  final SwitchBloc _switchBloc = SwitchBloc();
  List<dynamic> _deviceList = [];

  @override
  void initState() {
    fetchSwitches();
    super.initState();
  }

  void fetchSwitches() {
    _switchBloc.add(GetSwitchListEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Device List"),
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50), // roundness
        ),
        child: Icon(
          color: Theme.of(context).appColors.background,
          Icons.add,
        ),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const AddSwitchTab(),
          ));
        },
      ),
      body: BlocConsumer<SwitchBloc, CommonState>(
        bloc: _switchBloc,
        listener: (context, state) {
          ApiStatus apiResponse = state.apiStatus;
          if (apiResponse is ApiResponse) {
            final responseData = apiResponse.response;
            debugPrint("Response data====>$responseData");
            if (responseData != null) {
              final deviceList = responseData['data'] ?? [];
              _deviceList = deviceList;
            } else {
              debugPrint("Unexpected response format: $responseData");
            }
          }
        },
        builder: (context, state) {
          ApiStatus apiResponse = state.apiStatus;
          if (apiResponse is ApiResponse) {
            return _deviceList.isNotEmpty
                ? deviceListWidget()
                : CommonServices.noDataWidget();
          } else if (apiResponse is ApiLoadingState ||
              apiResponse is ApiInitialState) {
            return _deviceList.isEmpty
                ? const SwitchLoader()
                : deviceListWidget();
          } else if (apiResponse is ApiFailureState) {
            return Center(child: CommonServices.failureWidget(() {
              fetchSwitches();
            }));
          } else {
            return Container();
          }
        },
      ),
    );
  }

  TextEditingController _searchController = TextEditingController();
  Widget deviceListWidget() {
    if (_deviceList.isEmpty) {
      return Center(child: Image.asset("assets/images/no_switch.png"));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              height: MediaQuery.of(context).size.height * 0.08,
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
        // 💡 Device Cards List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(26),
            shrinkWrap: true,
            itemCount: _deviceList.length,
            itemBuilder: (context, index) {
              return SwitchesCard(
                searchController: _searchController,
                onChanged: () {
                  fetchSwitches();
                },
                switchesDetails: _deviceList[index],
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 15),
          ),
        ),
      ],
    );
  }
}

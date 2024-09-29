import 'package:flutter/material.dart';
import 'package:oshmobile/features/auth/presentation/pages/signin_page.dart';
import 'package:oshmobile/features/auth/presentation/pages/signup_page.dart';

class SignPage extends StatefulWidget {
  const SignPage({super.key});

  @override
  State<SignPage> createState() => _SignPageState();
}

class _SignPageState extends State<SignPage>
    with SingleTickerProviderStateMixin {
  // static const List<Tab> myTabs = <Tab>[
  // Tab(text: 'LEFT'),
  // Tab(text: 'RIGHT'),
  // ];

  final List<Widget> _tabList = [const SignInPage(), const SignUpPage()];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: _tabList.length);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: TabBar(
          controller: _tabController,
          // labelColor: _getTabLabelColor(context),
          indicatorColor: Theme.of(context).primaryColor,
          tabs: <Tab>[
            Tab(text: "Sign In"),
            Tab(text: "Sign Up"),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: _tabList,
        ),
      ),
    );
  }
}

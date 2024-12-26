import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:selectable_search_list/selectable_search_list.dart';

import '../../../themes/styles.dart';
import '../../../core/widgets/app_text_form_field.dart';
import '../../../core/widgets/app_button.dart';

class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key});

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  late TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('newGroup')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            nameField(),
            selectUsersList(),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  Expanded selectUsersList() {
    return Expanded(
      child: MultiSelectListWidget(
        searchHint: context.tr('search'),
        selectAllTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        itemTitleStyle:  const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        items: [
          ListItem(id: '1', title: 'Anything...'),
          ListItem(id: '2', title: 'Something...'),
          ListItem(id: '3', title: 'Nothing..'),
        ],
        onItemsSelect: (selectedItems) {
          print('Selected Items: ${selectedItems.length}');
        },
      ),
    );
  }

  Column nameField() {
    return Column(
      children: [
        AppTextFormField(
          hint: context.tr('name'),
          validator: (value) {
            if (value == null || value.isEmpty || value.startsWith(' ')) {
              return context.tr('pleaseEnterValid', args: ['Name']);
            }
          },
          controller: nameController,
        ),
        Gap(18.h),
      ],
    );
  }
}

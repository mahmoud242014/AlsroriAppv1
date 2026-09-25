import 'package:flutter/material.dart';

// Import Third Party Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

// Import App Files
import '../../../../utilities/functions.dart';
import '../widgets/snackbar.dart';

class ReportContentModal extends ConsumerStatefulWidget {
  final String id;
  final String handle;

  const ReportContentModal({
    required this.id,
    required this.handle,
    super.key,
  });

  @override
  ConsumerState<ReportContentModal> createState() => _ReportContentModalState();
}

class _ReportContentModalState extends ConsumerState<ReportContentModal> {
  final formKey = GlobalKey<FormState>();
  final reasonController = TextEditingController();
  dynamic selectedCategoryId;
  bool isSubmitLoading = false;
  var reportCategories = [];
  bool initialLoadDone = false;
  bool isLoading = false;

  // API Call: getCategories
  Future<void> getCategories() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });
    final response = await sendAPIRequest(
      'app/categories',
      queryParameters: {
        'get': 'reports_categories',
      },
    );
    if (response['statusCode'] == 200) {
      if (response['body']['data'] is List && response['body']['data'].isNotEmpty) {
        setState(() {
          reportCategories.addAll(response['body']['data']);
        });
      }
    } else {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(tr("There is something that went wrong!")),
          ),
        );
    }
    setState(() {
      isLoading = false;
      initialLoadDone = true;
    });
  }

  @override
  void initState() {
    super.initState();
    getCategories();
  }

  @override
  void dispose() {
    super.dispose();
    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          tr("Report"),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: SizedBox(width: 0),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Builder(
            builder: (context) {
              if (!initialLoadDone) {
                return Center(child: CircularProgressIndicator());
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Category
                        DropdownButtonFormField(
                          decoration: InputDecoration(
                            labelText: tr("Category"),
                          ),
                          items: reportCategories
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category['category_id'],
                                  child: Text(category['category_name']),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategoryId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return tr("Select valid category");
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Reason
                        TextFormField(
                          controller: reasonController,
                          maxLines: 6,
                          decoration: InputDecoration(
                            labelText: tr("Reason"),
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return tr("Enter valid reason");
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Submit
                        ElevatedButton(
                          onPressed: () async {
                            if (isSubmitLoading) return;
                            if (formKey.currentState!.validate()) {
                              setState(() {
                                isSubmitLoading = true;
                              });
                              final response = await sendAPIRequest(
                                'data/report',
                                method: 'POST',
                                body: {
                                  'id': widget.id,
                                  'handle': widget.handle,
                                  'category': selectedCategoryId,
                                  'reason': reasonController.text,
                                },
                              );
                              Navigator.pop(context);
                              setState(() {
                                isSubmitLoading = false;
                              });
                              if (response['statusCode'] == 200) {
                                ScaffoldMessenger.of(context)
                                  ..removeCurrentSnackBar()
                                  ..showSnackBar(snackBarSuccess(response['body']['message']));
                              } else {
                                ScaffoldMessenger.of(context)
                                  ..removeCurrentSnackBar()
                                  ..showSnackBar(snackBarError(response['body']['message']));
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: (isSubmitLoading)
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white),
                                )
                              : Text(tr("Submit")),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

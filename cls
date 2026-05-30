[1mdiff --git a/lib/modules/purchase/miraj/screens/vendor_offer_screen.dart b/lib/modules/purchase/miraj/screens/vendor_offer_screen.dart[m
[1mindex 812b9d4..cb5fb4d 100644[m
[1m--- a/lib/modules/purchase/miraj/screens/vendor_offer_screen.dart[m
[1m+++ b/lib/modules/purchase/miraj/screens/vendor_offer_screen.dart[m
[36m@@ -6,7 +6,7 @@[m [mimport 'package:firebase_storage/firebase_storage.dart';[m
 import 'package:flutter/material.dart';[m
 import 'package:url_launcher/url_launcher.dart';[m
 [m
[31m-class MirajVendorOfferScreen extends StatelessWidget {[m
[32m+[m[32mclass MirajVendorOfferScreen extends StatefulWidget {[m
   final String tenantId;[m
   final String currentUserUid;[m
 [m
[36m@@ -15,7 +15,10 @@[m [mclass MirajVendorOfferScreen extends StatelessWidget {[m
     required this.tenantId,[m
     required this.currentUserUid,[m
   });[m
[32m+[m[32m  @override[m
[32m+[m[32m  State<MirajVendorOfferScreen> createState() => _MirajVendorOfferScreenState();[m
 [m
[32m+[m[41m  [m
   CollectionReference<Map<String, dynamic>> get _offersRef => FirebaseFirestore[m
       .instance[m
       .collection('companies')[m
[36m@@ -359,26 +362,26 @@[m [mclass _MirajVendorOfferFormScreenState[m
   }[m
 [m
   Future<void> _addLine() async {[m
[31m-  final material = await showDialog<_SelectedRawMaterial>([m
[31m-    context: context,[m
[31m-    builder: (_) => _RawMaterialPickerDialog([m
[31m-      rawMaterialsRef: _rawMaterialsRef,[m
[31m-    ),[m
[31m-  );[m
[31m-[m
[31m-  if (material == null) return;[m
[31m-[m
[31m-  setState(() {[m
[31m-    _lines.add([m
[31m-      _VendorOfferLineInput([m
[31m-        productId: material.id,[m
[31m-        productName: material.materialCode,[m
[31m-        uom: material.uom,[m
[31m-        addToProductCost: false,[m
[31m-      )..descriptionController.text =[m
[31m-          '${material.description} • ${material.grade}',[m
[32m+[m[32m    final material = await showDialog<_SelectedRawMaterial>([m
[32m+[m[32m      context: context,[m
[32m+[m[32m      builder: (_) =>[m
[32m+[m[32m          _RawMaterialPickerDialog(rawMaterialsRef: _rawMaterialsRef),[m
     );[m
[31m-  });[m
[32m+[m
[32m+[m[32m    if (material == null) return;[m
[32m+[m
[32m+[m[32m    setState(() {[m
[32m+[m[32m      _lines.add([m
[32m+[m[32m        _VendorOfferLineInput([m
[32m+[m[32m            productId: material.id,[m
[32m+[m[32m            productName: material.materialCode,[m
[32m+[m[32m            uom: material.uom,[m
[32m+[m[32m            addToProductCost: false,[m
[32m+[m[32m          )[m
[32m+[m[32m          ..descriptionController.text =[m
[32m+[m[32m              '${material.description} • ${material.grade}',[m
[32m+[m[32m      );[m
[32m+[m[32m    });[m
   }[m
 [m
   Future<void> _save() async {[m
[36m@@ -1007,7 +1010,9 @@[m [mclass _OfferLineEditor extends StatelessWidget {[m
             contentPadding: EdgeInsets.zero,[m
             value: line.addToProductCost,[m
             title: const Text('Update raw material purchase rate'),[m
[31m-            subtitle: const Text('Applied when converting this offer into Purchase Order'),[m
[32m+[m[32m            subtitle: const Text([m
[32m+[m[32m              'Applied when converting this offer into Purchase Order',[m
[32m+[m[32m            ),[m
             onChanged: (value) {[m
               line.addToProductCost = value;[m
               onChanged();[m
[36m@@ -1064,9 +1069,7 @@[m [mclass _VendorOfferLineInput {[m
 class _RawMaterialPickerDialog extends StatelessWidget {[m
   final CollectionReference<Map<String, dynamic>> rawMaterialsRef;[m
 [m
[31m-  const _RawMaterialPickerDialog({[m
[31m-    required this.rawMaterialsRef,[m
[31m-  });[m
[32m+[m[32m  const _RawMaterialPickerDialog({required this.rawMaterialsRef});[m
 [m
   @override[m
   Widget build(BuildContext context) {[m
[36m@@ -1080,48 +1083,34 @@[m [mclass _RawMaterialPickerDialog extends StatelessWidget {[m
           builder: (context, snapshot) {[m
             final docs = snapshot.data?.docs ?? [];[m
 [m
[31m-            if (snapshot.connectionState ==[m
[31m-                    ConnectionState.waiting &&[m
[32m+[m[32m            if (snapshot.connectionState == ConnectionState.waiting &&[m
                 !snapshot.hasData) {[m
[31m-              return const Center([m
[31m-                child: CircularProgressIndicator(),[m
[31m-              );[m
[32m+[m[32m              return const Center(child: CircularProgressIndicator());[m
             }[m
 [m
             if (docs.isEmpty) {[m
[31m-              return const Center([m
[31m-                child: Text('No raw materials found'),[m
[31m-              );[m
[32m+[m[32m              return const Center(child: Text('No raw materials found'));[m
             }[m
 [m
             return ListView.separated([m
               itemCount: docs.length,[m
[31m-              separatorBuilder: (_, __) =>[m
[31m-                  const Divider(height: 1),[m
[32m+[m[32m              separatorBuilder: (_, __) => const Divider(height: 1),[m
               itemBuilder: (context, index) {[m
                 final doc = docs[index];[m
                 final data = doc.data();[m
 [m
                 final material = _SelectedRawMaterial([m
                   id: doc.id,[m
[31m-                  materialCode:[m
[31m-                      (data['materialCode'] ?? '').toString(),[m
[31m-                  description:[m
[31m-                      (data['description'] ?? '').toString(),[m
[31m-                  grade:[m
[31m-                      (data['grade'] ?? '').toString(),[m
[31m-                  uom:[m
[31m-                      (data['uom'] ?? 'KG').toString(),[m
[32m+[m[32m                  materialCode: (data['materialCode'] ?? '').toString(),[m
[32m+[m[32m                  description: (data['description'] ?? '').toString(),[m
[32m+[m[32m                  grade: (data['grade'] ?? '').toString(),[m
[32m+[m[32m                  uom: (data['uom'] ?? 'KG').toString(),[m
                 );[m
 [m
                 return ListTile([m
[31m-                  leading: const Icon([m
[31m-                    Icons.inventory_2_outlined,[m
[31m-                  ),[m
[32m+[m[32m                  leading: const Icon(Icons.inventory_2_outlined),[m
                   title: Text(material.materialCode),[m
[31m-                  subtitle: Text([m
[31m-                    '${material.description} • ${material.grade}',[m
[31m-                  ),[m
[32m+[m[32m                  subtitle: Text('${material.description} • ${material.grade}'),[m
                   trailing: Text(material.uom),[m
                   onTap: () {[m
                     Navigator.pop(context, material);[m

import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  List<html.File> selectedFiles = [];
  List<String> uploadedUrls = [];
  bool isUploading = false;
  int uploadedCount = 0;
  int totalCount = 0;

  Future<void> _selectFiles() async {
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.multiple = true;
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        setState(() {
          selectedFiles = files;
        });
        html.document.body!.append(uploadInput);
        uploadInput.remove();
      }
    });
  }

  Future<Uint8List> _readFile(html.File file) async {
    final reader = html.FileReader();
    final completer = Completer<Uint8List>();

    reader.readAsArrayBuffer(file);

    reader.onLoad.listen((event) {
      print('✅ Dosya okundu: ${reader.result.runtimeType}');
      final result = reader.result;
      if (result is Uint8List) {
        completer.complete(Uint8List.fromList(result));
      } else if (result is ByteBuffer) {
        completer.complete(Uint8List.view(result));
      } else {
        completer.completeError('❌ Bilinmeyen veri tipi: ${result.runtimeType}');
      }
    });

    reader.onError.listen((error) {
      print('❌ Dosya okuma hatası: $error');
      completer.completeError(error);
    });

    return completer.future;
  }

  Future<void> _uploadFiles() async {
    if (_nameController.text.isEmpty || _surnameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ad ve Soyad boş bırakılamaz.")),
      );
      return;
    }

    if (selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yüklenecek dosya seçilmedi.")),
      );
      return;
    }

    setState(() {
      isUploading = true;
      uploadedUrls.clear();
      uploadedCount = 0;
      totalCount = selectedFiles.length;
    });


      for (final file in selectedFiles) {
try{
        final bytes = await _readFile(file);
        final ref = FirebaseStorage.instance
            .ref()
            .child("uploads/${DateTime.now().millisecondsSinceEpoch}_${file.name}");
        final uploadTask = await ref.putData(bytes);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);


        setState(() {
          uploadedCount++;
        });
      } catch (e) {
    debugPrint('Yükleme hatası: $e');
    }

      }
    setState(() {
      isUploading = false;
      uploadedCount = 0;
      totalCount = 0;
      selectedFiles = []; // Listeyi resetle
    });
      await FirebaseFirestore.instance.collection("uploads").add({
        'ad': _nameController.text.trim(),
        'soyad': _surnameController.text.trim(),
        'tarih': Timestamp.now(),
        'dosyalar': uploadedUrls,
      });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Tüm dosyalar başarıyla yüklendi!')),
      );
    }

    setState(() {
      isUploading = false;
      selectedFiles.clear();
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Tüm dosyalar başarıyla yüklendi!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Simge & Melih"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Ad'),
            ),
            TextField(
              controller: _surnameController,
              decoration: const InputDecoration(labelText: 'Soyad'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectFiles,
              child: const Text("Dosya Seç"),
            ),
            const SizedBox(height: 8),
            Text("Seçilen dosya sayısı: ${selectedFiles.length}"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isUploading ? null : _uploadFiles,
              child: const Text('Dosyaları Yükle'),
            ),
            const SizedBox(height: 20),
            if (isUploading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              Text(
                'Yükleniyor: $uploadedCount / $totalCount',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

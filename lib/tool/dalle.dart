import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ChatMcp/provider/provider_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class GenerationImageRequest {
  final String model;
  final String prompt;
  final int n;
  final String size;

  GenerationImageRequest({
    this.model = 'dall-e-3',
    required this.prompt,
    this.n = 1,
    String? size,
  }) : size = _validateSize(size);

  static String _validateSize(String? size) {
    if (size == null) return '1024x1024';
    if (!['1024x1024', '1024x1792', '1792x1024'].contains(size)) {
      return '1024x1024';
    }
    return size;
  }

  Map<String, dynamic> toJson() => {
        'model': model,
        'prompt': prompt,
        'n': n,
        'size': size,
      };
}

class GenerationImageData {
  final String url;
  final dynamic b64Json;
  final String revisedPrompt;
  final String size;
  int width;
  int height;

  GenerationImageData({
    required this.url,
    this.b64Json,
    required this.revisedPrompt,
    required this.size,
    required this.width,
    required this.height,
  });

  factory GenerationImageData.fromJson(Map<String, dynamic> json) {
    return GenerationImageData(
      url: json['url'] as String,
      b64Json: json['b64_json'],
      revisedPrompt: json['revised_prompt'] as String,
      size: json['size'] ?? '1024x1024',
      width: json['width'] ?? 1024,
      height: json['height'] ?? 1024,
    );
  }
}

class GenerationImageResponse {
  final int created;
  final List<GenerationImageData> data;

  GenerationImageResponse({
    required this.created,
    required this.data,
  });

  factory GenerationImageResponse.fromJson(Map<String, dynamic> json) {
    return GenerationImageResponse(
      created: json['created'] as int,
      data: (json['data'] as List)
          .map((e) => GenerationImageData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GenerationImageResult {
  final String url;
  final String prompt;
  final String size;

  GenerationImageResult({
    required this.url,
    required this.prompt,
    required this.size,
  });

  factory GenerationImageResult.fromJson(Map<String, dynamic> json) {
    return GenerationImageResult(
      url: json['url'] as String,
      prompt: json['prompt'] as String,
      size: json['size'] as String,
    );
  }

  @override
  String toString() {
    return json.encode({
      'url': url,
      'prompt': prompt,
      'size': size,
    });
  }
}

class DalleClient {
  final Dio _dio;

  DalleClient() : _dio = Dio();

  Future<GenerationImageResult> generateImage(
      GenerationImageRequest request) async {
    try {
      final openai = ProviderManager.settingsProvider.apiSettings['openai'];

      print('开始生成图片请求');
      print('请求数据: ${request.toJson()}');
      print('API地址: ${openai?.apiEndpoint}');

      Response response;
      try {
        response = await _dio.post(
          '${openai?.apiEndpoint}/images/generations',
          data: request.toJson(),
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${openai?.apiKey}',
            },
          ),
        );
        print('API响应: ${response.data}');
        print('响应状态码: ${response.statusCode}');
        print('响应数据类型: ${response.data.runtimeType}');
      } catch (e) {
        print('API请求错误: $e');
        rethrow;
      }

      if (response.statusCode != 200) {
        final errorMsg = response.data['error']?['message'] ?? '未知错误';
        throw Exception('生成图片失败: $errorMsg');
      }

      print('Response data: ${response.data}');
      final imageResp = GenerationImageResponse.fromJson(
          response.data as Map<String, dynamic>);

      if (imageResp.data.isEmpty) {
        throw Exception('没有生成任何图片');
      }

      print('Image response data: ${imageResp.data}');

      // 更新尺寸信息
      final data = imageResp.data[0];
      switch (request.size) {
        case '1024x1024':
          data.width = 1024;
          data.height = 1024;
          break;
        case '1024x1792':
          data.width = 1024;
          data.height = 1792;
          break;
        case '1792x1024':
          data.width = 1792;
          data.height = 1024;
          break;
      }

      return GenerationImageResult(
        url: data.url,
        prompt: request.prompt,
        size: request.size,
      );
    } catch (e, trace) {
      if (e is DioException) {
        final errorMsg = e.response?.data['error']?['message'] ?? e.message;
        throw Exception('生成图片失败: $errorMsg');
      }
      throw Exception('生成图片失败: $e, trace: $trace');
    }
  }
}

class DalleImageResultWidget extends StatelessWidget {
  final GenerationImageResult result;

  const DalleImageResultWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 提示词显示
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '提示词: ${result.prompt}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          // 图片展示
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => launchUrl(Uri.parse(result.url)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CachedNetworkImage(
                    imageUrl: result.url,
                    placeholder: (context, url) => Container(
                      width: double.infinity,
                      height: 200,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: double.infinity,
                      height: 200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.error),
                    ),
                    fit: BoxFit.contain,
                  ),
                  // 尺寸信息
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '尺寸: ${result.size}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => launchUrl(Uri.parse(result.url)),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text(
                            '在浏览器中打开',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

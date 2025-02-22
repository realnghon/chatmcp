import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatmcp/provider/provider_manager.dart';
import 'package:chatmcp/provider/settings_provider.dart';

const String tavilySearchURL = 'https://api.tavily.com/search';

class TavilySearchRequest {
  final String query;
  final int maxResults;

  TavilySearchRequest({required this.query, this.maxResults = 10});

  Map<String, dynamic> toJson() => {
        'query': query,
        'max_results': maxResults,
      };
}

class TavilySearchResult {
  final String title;
  final String url;
  final String content;
  final double score;

  TavilySearchResult({
    required this.title,
    required this.url,
    required this.content,
    required this.score,
  });

  factory TavilySearchResult.fromJson(Map<String, dynamic> json) {
    return TavilySearchResult(
      title: json['title'] as String,
      url: json['url'] as String,
      content: json['content'] as String,
      score: (json['score'] as num).toDouble(),
    );
  }
}

class TavilySearchResponse {
  final List<TavilySearchResult> results;

  TavilySearchResponse({required this.results});

  factory TavilySearchResponse.fromJson(Map<String, dynamic> json) {
    final resultsList = (json['results'] as List)
        .map((result) =>
            TavilySearchResult.fromJson(result as Map<String, dynamic>))
        .toList();
    return TavilySearchResponse(results: resultsList);
  }

  @override
  String toString() {
    return json.encode({
      'results': results
          .map((result) => {
                'title': result.title,
                'url': result.url,
                'content': result.content,
                'score': result.score,
              })
          .toList(),
    });
  }
}

class TavilySearchClient {
  final Dio _dio;

  TavilySearchClient() : _dio = Dio();

  Future<TavilySearchResponse> search(TavilySearchRequest request) async {
    if (request.query.isEmpty) {
      throw Exception('搜索查询词不能为空');
    }

    try {
      KeysSetting? settingsProvider =
          ProviderManager.settingsProvider.apiSettings['tavily'];
      if (settingsProvider == null) {
        throw Exception('Tavily API 密钥未设置');
      }
      final response = await _dio.post(
        tavilySearchURL,
        data: {
          'api_key': settingsProvider.apiKey,
          'query': request.query,
          'search_depth': 'basic',
          'max_results': request.maxResults,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('调用 tavily 搜索出错: ${response.data}');
      }

      return TavilySearchResponse.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('调用 tavily 搜索失败: $e');
    }
  }
}

class TavilySearchResultWidget extends StatelessWidget {
  final TavilySearchResponse response;

  const TavilySearchResultWidget({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    return Container(
      // constraints: const BoxConstraints(maxHeight: 400),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: response.results.length,
        itemBuilder: (context, index) {
          final result = response.results[index];
          return Card(
            child: InkWell(
              onTap: () => launchUrl(Uri.parse(result.url)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    CachedNetworkImage(
                      imageUrl: 'https://favicon.im/${result.url}',
                      placeholder: (context, url) => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.public, size: 8),
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        result.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

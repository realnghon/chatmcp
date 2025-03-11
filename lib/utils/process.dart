import 'dart:io';
import 'package:logging/logging.dart';

Future<String> getDefaultPath([String? additionalPath]) async {
  final List<String> defaultPaths = [];

  if (Platform.isWindows) {
    defaultPaths.addAll([
      'C:\\Windows\\System32',
      'C:\\Windows',
      'C:\\Windows\\System32\\Wbem',
      'C:\\Windows\\System32\\WindowsPowerShell\\v1.0',
    ]);
  } else if (Platform.isMacOS) {
    defaultPaths.addAll([
      '/opt/homebrew/bin',
      '/usr/local/bin',
      '/usr/bin',
      '/bin',
      '/usr/sbin',
      '/sbin',
    ]);
  } else {
    defaultPaths.addAll([
      '/usr/local/bin',
      '/usr/bin',
      '/bin',
      '/usr/sbin',
      '/sbin',
    ]);
  }

  final String pathSeparator = Platform.isWindows ? ';' : ':';
  final String systemPath = Platform.environment['PATH'] ?? '';

  // 合并默认路径、系统PATH和额外路径
  final List<String> allPaths = [
    ...defaultPaths,
    ...systemPath.split(pathSeparator),
  ];

  // 如果提供了额外的路径，添加到列表中
  if (additionalPath != null && additionalPath.isNotEmpty) {
    allPaths.addAll(additionalPath.split(pathSeparator));
  }

  // 移除空路径并去重
  return allPaths.where((path) => path.isNotEmpty).toSet().join(pathSeparator);
}

Future<bool> isCommandAvailable(String command) async {
  try {
    final String whichCommand = Platform.isWindows ? 'where' : 'which';
    final Map<String, String> env = Map.of(Platform.environment);
    env['PATH'] = await getDefaultPath();

    final result = await Process.run(
      whichCommand,
      [command],
      environment: env,
      includeParentEnvironment: true,
    );

    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}

Map<String, String>? _cachedEnv;

Future<Map<String, String>> _loadShellEnv() async {
  if (!Platform.isMacOS && !Platform.isLinux) {
    return {};
  }

  try {
    // 获取用户的默认 shell
    final String shell = Platform.environment['SHELL'] ?? '/bin/bash';
    final String homeDir = Platform.environment['HOME'] ?? '';
    final String user = Platform.environment['USER'] ?? '';

    // 创建一个临时脚本来加载环境变量
    final tempDir = await Directory.systemTemp.createTemp('env_loader');
    final scriptFile = File('${tempDir.path}/load_env.sh');
    
    // 写入环境加载脚本
    await scriptFile.writeAsString('''
#!/bin/sh
# 设置基本环境
export HOME="$homeDir"
export USER="$user"
export SHELL="$shell"
export TERM="xterm-256color"
export LANG="en_US.UTF-8"
export ENV_PREPARED=1

# 加载系统级配置
if [ -f /etc/profile ]; then
  . /etc/profile
fi

# 根据不同的 shell 加载配置
if [ -n "\$BASH_VERSION" ]; then
  if [ -f "\$HOME/.bash_profile" ]; then
    . "\$HOME/.bash_profile"
  elif [ -f "\$HOME/.bash_login" ]; then
    . "\$HOME/.bash_login"
  elif [ -f "\$HOME/.profile" ]; then
    . "\$HOME/.profile"
  fi
elif [ -n "\$ZSH_VERSION" ]; then
  if [ -f "\$HOME/.zshrc" ]; then
    . "\$HOME/.zshrc"
  fi
fi

# 输出所有环境变量
env
''');

    // 设置脚本权限
    await Process.run('chmod', ['+x', scriptFile.path]);

    // 执行脚本获取环境变量
    final result = await Process.run(shell, [
      scriptFile.path
    ], environment: {
      'HOME': homeDir,
      'USER': user,
      'SHELL': shell,
      'TERM': 'xterm-256color',
      'PATH': '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    });

    // 清理临时文件
    await tempDir.delete(recursive: true);

    if (result.exitCode != 0) {
      Logger.root.warning('Failed to load shell environment: ${result.stderr}');
      return {};
    }

    // 解析环境变量
    final Map<String, String> env = {};
    final lines = result.stdout.toString().split('\n');
    for (final line in lines) {
      final parts = line.split('=');
      if (parts.length >= 2) {
        final key = parts[0];
        final value = parts.sublist(1).join('=');
        env[key] = value;
      }
    }

    Logger.root.info('Loaded shell environment: $env');

    return env;
  } catch (e) {
    Logger.root.severe('Error loading shell environment: $e');
    return {};
  }
}

Future<Map<String, String>> getDefaultEnv() async {
  // 如果已经加载过环境变量，直接返回缓存
  if (_cachedEnv != null) {
    return Map.of(_cachedEnv!);
  }
  final Map<String, String> env = await Map.of(Platform.environment);
  if (Platform.isWindows) {
    env['PYTHONIOENCODING'] = 'utf-8';
    env['PYTHONLEGACYWINDOWSSTDIO'] = 'utf-8';
  } else if (Platform.isMacOS || Platform.isLinux) {
    // 标记环境变量已准备
    env['ENV_PREPARED'] = '1';

    final Map<String, String> shellEnv = await _loadShellEnv();
    if (shellEnv.containsKey('PATH')) {
      final String newPath = shellEnv['PATH']!;
      Logger.root.info('Loaded PATH from shell: $newPath');
      env['PATH'] = newPath;
    } else {
      final String defaultPath = await getDefaultPath();
      Logger.root.info('Using default PATH: $defaultPath');
      env['PATH'] = defaultPath;
    }

    // 合并其他环境变量
    shellEnv.forEach((key, value) {
      if(key!='PATH'&&!env.containsKey(key)) {
        env[key] = value;
      }
    });
  }
  Logger.root.info('Default environment: $env');
  return env;
}

Future<Process> startProcess(
  String command,
  List<String> args,
  Map<String, String> environment,
) async {
  final Map<String, String> env = await getDefaultEnv();
  env.addAll(environment); // Add user provided environment variables

  return Process.start(
    command,
    args,
    environment: env,
    includeParentEnvironment: true,
    // Windows need it to run properly, no idea why. Keep other platforms as default value (false).
    runInShell: Platform.isWindows,
  );
}
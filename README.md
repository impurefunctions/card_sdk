<!--
 * @Author: your name
 * @Date: 2022-03-14 15:40:26
 * @LastEditTime: 2022-04-02 23:18:10
 * @LastEditors: Please set LastEditors
 * @Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 * @FilePath: /Flutter_work/card_sdk/README.md
-->
# card_sdk

A new flutter plugin project.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


1. 清空缓存。
2. 在文件 CHANGELOG.md 增加修改内容
3. 代码提交检查
flutter packages pub publish --dry-run
4. 修改命令行代理
set http_proxy=http://127.0.0.1:10001
set https_proxy=http://127.0.0.1:10001
不同系统设置命令行代理
powershell
$env:https_proxy = "127.0.0.1:1080"
$env:http_proxy = "127.0.0.1:1080"
git-bash
export http_proxy='127.0.0.1:9999'
export https_proxy='127.0.0.1:9999'
cmd
set http_proxy='127.0.0.1:1080'
set https_proxy='127.0.0.1:1080'

测试命令行网络
curl https://www.google.com.hk/

5. 提交代码
flutter packages pub publish

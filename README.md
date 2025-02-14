<div align="center">
<img src="./macos/Runner/Assets.xcassets/AppIcon.appiconset/icon_128@1x.png" alt="logo">
<h1>chatmcp</h1>

Cross-platform `Macos | Windows | Linux | iOS | Android` AI Chat Client

</div>

## Install

Desktop: MacOS | Windows | Linux [Download for release](https://github.com/daodao97/chatmcp/releases) 

IOS: [TestFlight](https://testflight.apple.com/join/dCXksFJV)

Android: need to build in your local

## Preview

### Deep Think
![preview](./assets/preview/think.png)

### Artifact generation and review
![preview](./assets/preview/artifact.png)

### Dalle Gen Image
![preview](./assets/preview/gen_img.png)

### HTML Code Preview
![preview](./assets/preview/html.png)

### MCP Fetch Url
![preview](./assets/preview/mcp_fetch.png)

### Mermaid Diagram
![preview](./assets/preview/mermaid.png)

### Web Search
![preview](./assets/preview/web_search.png)

## Usage

Make sure you have installed `uvx` or `npx` in your system

```bash
# uvx
brew install uv

# npx
brew install node 
```

1. Configure Your LLM API Key and Endpoint in `Setting` Page
2. Install MCP Server from `MCP Server` Page
3. Chat with MCP Server

## Debug 

- logs 

`~/Library/Application Support/run.daodao.chatmcp/logs`

- data

`~/Library/Application Support/ChatMcp`


reset app can use this command

```bash
rm -rf ~/Library/Application\ Support/run.daodao.chatmcp
rm -rf ~/Library/Application\ Support/ChatMcp
```

## Development

```bash
flutter pub get
flutter run -d macos
```

download [test.db](./assets/test.db) to test sqlite mcp server

![](./assets/test.png)

`~/Library/Application Support/ChatMcp/mcp_server.json` is the configuration file for the mcp server

## Features

- [x] Chat with MCP Server
- [ ] MCP Server Market
- [ ] Auto install MCP Server
- [ ] SSE MCP Transport Support
- [x] Auto Choose MCP Server
- [x] Chat History
- [x] OpenAI LLM Model
- [x] Claude LLM Model
- [x] OLLama LLM Model
- [x] DeepSeek LLM Model
- [ ] RAG 
- [ ] Better UI Design
- [x] Dark/Light Theme

All features are welcome to submit, you can submit your ideas or bugs in [Issues](https://github.com/daodao97/chatmcp/issues)

## MCP Server Market

You can install MCP Server from MCP Server Market, MCP Server Market is a collection of MCP Server, you can use it to chat with different data.

Your feedback helps us improve chatmcp and helps other users make informed decisions.

## Thanks

- [MCP](https://modelcontextprotocol.io/introduction)
- [mcp-cli](https://github.com/chrishayuk/mcp-cli)

## License

This project is licensed under the [Apache License 2.0](./LICENSE).

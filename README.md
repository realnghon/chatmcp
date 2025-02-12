<div align="center">
<img src="./macos/Runner/Assets.xcassets/AppIcon.appiconset/icon_128@1x.png" alt="logo">
<h1>chatmcp</h1>

AI Chat with [MCP](https://modelcontextprotocol.io/introduction) Server use Any LLM Model
</div>

## Preview

### Artifact
![preview](./assets/artifact.png)

### Gen Image
![preview](./assets/gen_image.png)

### HTML
![preview](./assets/html.png)

### Fetch
![preview](./assets/mcp_fetch.png)

### Mermaid
![preview](./assets/mermain.png)

### Web Search
![preview](./assets/web_search.png)

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

## Install

[Download](https://github.com/daodao97/chatmcp/releases)  MacOS | Windows | Linux


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

All features are welcome to submit, you can submit your ideas or bugs in [Issues](https://github.com/daodao97/chatmcp/issues)

## MCP Server Market

You can install MCP Server from MCP Server Market, MCP Server Market is a collection of MCP Server, you can use it to chat with different data.

Your feedback helps us improve chatmcp and helps other users make informed decisions.

## Thanks

- [MCP](https://modelcontextprotocol.io/introduction)
- [mcp-cli](https://github.com/chrishayuk/mcp-cli)

## License

This project is licensed under the [Apache License 2.0](./LICENSE).

# Tauri + React + Typescript

This template should help get you started developing with Tauri, React and Typescript in Vite.

## Recommended IDE Setup

- [VS Code](https://code.visualstudio.com/) + [Tauri](https://marketplace.visualstudio.com/items?itemName=tauri-apps.tauri-vscode) + [rust-analyzer](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer)




# Nova assistant 

## Overview

The **Nova assistant** is a privacy-first, fully offline-capable cross platform application designed to function as a customizable personal assistant. It provides core functionalities like chat, memory management, voice interaction, and plugin execution, all running locally on your device to ensure full control and privacy.

This MVP aims to provide a lean, fast, and functional version of the assistant with a focus on extensibility and performance, enabling users to have a personalized AI experience without needing an internet connection.

## Key Features

### **Core Features**
- **Local LLM (Mistral Uncensored)**: A powerful local language model running offline, ensuring user privacy.
- **Chat UI**: An interactive, user-friendly interface for chatting with the assistant.
- **Memory**: A built-in SQLite database to store conversation history and summaries for context.
- **Plugin Support**: Extend the assistant’s functionality with custom plugins, either written in Rust or WebAssembly.
- **Voice Interaction**: Offline speech-to-text (STT) and text-to-speech (TTS) capabilities, providing voice input and output.

### **Future Enhancements**
- **Embedding-based Memory**: Advanced context retention for long-term conversations.
- **Wake Word**: Activate the assistant using a wake word for hands-free control.
- **Plugin Sandboxing**: Secure plugin execution with WASM support.
- **Multi-Agent Architecture**: Support for multiple assistant personalities or specialized functions.
- **Local Knowledge Ingestion**: Ability to ingest local files like PDFs or text documents for reference.

## Architecture

The application is built with **Tauri**, combining a **Rust** backend and an **HTML/CSS/JS** frontend for a responsive, lightweight experience. Here’s an overview of the components:

- **Frontend UI**: Displays the chat interface and allows interaction with the assistant.
- **LLM Core**: Handles the local LLM model (Mistral Uncensored) and manages prompt/response generation.
- **Memory DB**: SQLite database that stores conversation history and context.
- **Plugin Executor**: Dynamically loads and executes user-created plugins.
- **Call Handler**: Manages voice input and output using offline STT and TTS engines.

## Installation

### Requirements
- **Rust** (for backend development): [Install Rust](https://www.rust-lang.org/tools/install)
- **Node.js** (for frontend development): [Install Node.js](https://nodejs.org/)
- **Tauri**: [Tauri Setup Guide](https://tauri.app/v1/guides/getting-started)

### Running Locally

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/ChaotixG/Nova.git
   ```

2. **Install Dependencies**:
   - Install Rust and Tauri as outlined in the [Tauri Setup Guide](https://tauri.app/v1/guides/getting-started).
   - Install Node.js for the frontend part.

3. **Build the Application**:
   ```bash
   cargo tauri dev
   ```

4. **Run the Application**:
   This will start the application in development mode, with live-reload enabled for frontend changes.

## Development Guide

### Adding Plugins

Plugins can be added by placing `.rs` (Rust) or `.wasm` (WebAssembly) files in the `plugins/` directory. Each plugin should have a `plugin.toml` manifest file that defines the plugin’s interface and configuration.

### Voice Interaction

The voice interaction uses offline speech recognition (Whisper or Vosk) for STT and Coqui TTS or OS-native TTS for voice output. This ensures that all voice processing is done locally without relying on the cloud.

### Memory Management

The assistant stores conversations and summaries in a local SQLite database. A context window is used to maintain relevant conversation history, making interactions more personalized and context-aware.

## Roadmap

### **MVP Features**
- Tauri app scaffolded
- Local Mistral model integrated
- Chat UI, memory management, and plugin folder
- Voice interaction with STT and TTS

### **Future Milestones**
- **Embedding-based Memory**: Implement advanced memory systems for long-term context retention.
- **Plugin Sandboxing**: Introduce secure sandboxing for plugins using WASM.
- **Multi-Agent Support**: Add the ability to switch between multiple assistant personalities or functions.
- **Local Knowledge Ingestion**: Ability to ingest local documents (PDFs, txt) for dynamic knowledge.

## Feedback & Contributions

We welcome contributions from the community. Feel free to open issues or submit pull requests for bug fixes, new features, or improvements. For more information on how to contribute, please refer to the [Contributing Guide](CONTRIBUTING.md).

---

*Built with privacy and extensibility in mind, this assistant puts control back in the hands of the user, offering an offline, customizable experience for personal AI assistance.*

## License

This project is licensed under the MIT License.

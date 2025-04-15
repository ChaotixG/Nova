= SPEC-1: Local AI Assistant MVP
:sectnums:
:toc:

== Background

With the rising need for privacy-first and locally-controlled AI assistants, this project aims to build a desktop application that operates fully offline, supports customizable models and plugins, and eventually serves as a secure and extensible personal assistant. The MVP targets a fast, lean, and functional version of this assistant with core chat, memory, voice, and plugin execution capabilities.

== Requirements

=== *Must Have*

- [ ] Local LLM (Mistral Uncensored) running efficiently
- [ ] Chat UI with prompt/response streaming
- [ ] Local memory via SQLite (conversation history)
- [ ] Plugin folder for user-created extensions
- [ ] Call mode (voice input/output)

=== *Should Have*

- [ ] Embedding-based memory for long-term context
- [ ] Wake word activation for voice
- [ ] Plugin manifest schema
- [ ] Plugin sandboxing support via WASM

=== *Could Have*

- [ ] Multi-agent architecture
- [ ] Remote model orchestration via Docker
- [ ] Local knowledge file ingestion

== Method

The assistant desktop application is built using Tauri (Rust backend + HTML/CSS/JS frontend) to offer strong performance and plugin isolation. The MVP architecture is composed of the following components:





## [plantuml, arch, svg]
@startuml
package "Tauri App" {
[Frontend UI] --> [Tauri Commands]
[Tauri Commands] --> [LLM Core]
[Tauri Commands] --> [Memory DB]
[Tauri Commands] --> [Plugin Executor]
[Tauri Commands] --> [Call Handler]
}

database "Memory DB" {
[SQLite]
}

package "LLM Core" {
[Local LLM Engine]
[Model Loader]
}

package "Plugin Executor" {
[Plugins Folder] --> [Function Executor]
}

package "Call Handler" {
[Whisper or Vosk] --> [STT Module]
[TTS Module] --> [System Audio]
}

[LLM Core] --> [Model Loader]
[Model Loader] --> [Local LLM Engine]
[Local LLM Engine] --> [Memory DB]
[Local LLM Engine] --> [Function Executor]

@enduml





== LLM Core

- Default model: *Mistral Uncensored*, run via `llama.cpp`-compatible backend.
- Models loaded via a wrapper over `llama.cpp` or `llm.rs`, optionally controlled through `ollama`.
- The backend handles prompt formatting, token streaming, and memory management.

Future roadmap:
- User-selectable models
- Plugin-based custom model integration
- Remote model offloading via Docker RPC or LAN service discovery

=== Chat UI

- HTML/CSS/JS frontend in Tauri WebView.
- Conversation display + input prompt.
- Streaming response rendering.
- JSON-based metadata stream for triggering plugins or call mode.

=== Memory

- Lightweight SQLite DB.
- Stores conversation history, summaries, and embedding vectors (optional).
- Query model for context retrieval (simple windowing or similarity-based).

=== Plugin Folder

- Developers drop `.rs` or `.wasm` files in a `plugins/` folder.
- Each plugin has manifest metadata (`plugin.toml`) and exposes a known interface.
- Initially, plugins run unsandboxed via dynamic linking or subprocess.

=== Call Mode

- Voice input: Offline STT using Whisper.cpp or Vosk.
- Voice output: TTS via Coqui TTS or OS-native TTS.
- Triggered by wake phrase or button in UI.

== Implementation

=== Phase 1: Project Bootstrap

- Initialize Tauri app scaffold with Rust + Web frontend
- Create basic layout: sidebar, chat window, input bar
- Setup SQLite for local persistence
- Define interop bridge between frontend and Rust backend

=== Phase 2: Local LLM Integration

- Integrate Mistral Uncensored via llama.cpp backend or compatible runner
- Load model weights and ensure prompt → response works
- Implement basic context windowing (N-last messages)
- Add stream-based UI rendering in the chat view

=== Phase 3: Memory System

- Create schema in SQLite:
  - `conversations(id, title, created_at)`
  - `messages(id, conversation_id, role, content, created_at)`
- Add functions to save/load chat history
- Optionally: add embedding vector storage for retrieval later

=== Phase 4: Plugin Execution

- Setup `plugins/` folder
- Define plugin manifest format (`plugin.toml`)
- Load plugins dynamically via Rust modules or WASM interface
- Define simple function call protocol (JSON in/out)
- Trigger plugin execution from LLM response metadata

=== Phase 5: Call Mode

- Integrate STT: Whisper.cpp or Vosk (offline, no cloud)
- Integrate TTS: Coqui TTS or OS-native engine
- UI button to toggle voice interaction
- Enable wake word later (future phase)

== Milestones

=== MVP (Minimum Viable Product)

- ✅ Tauri app scaffolded
- Local Mistral model integrated
- Chat UI + memory + plugin folder
- Voice mode with STT + TTS

=== Milestone 1: LLM + Plugin Extensibility

- Model FFI integration
- Model abstraction layer (multi-LLM support)
- User-selectable models via config or UI
- Plugin sandboxing via WASM with syscall restrictions
- Secure plugin manifest validation
- Plugin settings UI (toggle/permission/config)

=== Milestone 2: Offline Intelligence

- Embedding-based memory search
- Summary-based compression for older chats
- Local knowledge file ingestion (PDF, txt)
- Context-aware prompt builder for longer history

=== Milestone 3: Remote + Multi-Agent Support

- Remote model execution via Docker config or LAN discovery
- Agent schema (multiple personalities/functions)
- Agent switching within chats
- Message routing to agent-specific logic

=== Milestone 4: Ecosystem + Dev Experience

- CLI for managing models, plugins, configs
- Plugin SDK (Rust + WASM templates)
- Plugin registry (local index, future: remote hub)
- Plugin update/version system

=== Milestone 5: Polished Assistant UX

- Full theming / light-dark mode
- UI-based config and log viewer
- Smooth voice interaction + wake word
- OS tray integration, global hotkeys

== Gathering Results

- Evaluate assistant's latency (prompt to token output)
- Track memory effectiveness via embedding retrieval accuracy
- Plugin execution safety and performance benchmarks
- User feedback on voice mode usability and plugin integration
- Collect telemetry locally (opt-in) to refine prompt templates and memory models
- Results will inform model tuning, plugin architecture, and UX improvements in future releases

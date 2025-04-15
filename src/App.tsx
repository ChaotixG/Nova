// App.tsx
import { useEffect, useState, useRef } from "react";
import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import "./App.css";

interface Message {
  sender: "user" | "ai";
  content: string;
}

function App() {
  const [userInput, setUserInput] = useState("");
  const [messages, setMessages] = useState<Message[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const chatEndRef = useRef<HTMLDivElement>(null);

  // Listen to streaming messages from the backend.
  useEffect(() => {
    const unlisten = listen<string>("stream_chunk", (event) => {
      setMessages((prev) => {
        const updated = [...prev];
        const lastMessage = updated[updated.length - 1];
        if (lastMessage?.sender === "ai") {
          // Append streamed content to the last AI message.
          lastMessage.content += event.payload;
        } else {
          // In case no AI message exists, push a new one.
          updated.push({ sender: "ai", content: event.payload });
        }
        return updated;
      });
    });

    return () => {
      unlisten.then((f) => f());
    };
  }, []);

  // Auto-scroll to the bottom when messages update.
  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!userInput.trim()) return;

    // Append user's message.
    setMessages((prev) => [...prev, { sender: "user", content: userInput }]);
    setError(null);
    setIsLoading(true);
    const currentPrompt = userInput;
    setUserInput("");

    try {
      // Invoke the backend function to stream the AI response.
      await invoke("run_llm_stream", { prompt: currentPrompt });
    } catch (err) {
      console.error("Error invoking run_llm_stream:", err);
      setError("Something went wrong. Please try again.");
      // Optionally, add a system message indicating error.
      setMessages((prev) => [
        ...prev,
        { sender: "ai", content: "Error: Unable to retrieve a response." },
      ]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main className="chat-container">
      <header className="chat-header">Nova Chat</header>
      <section className="chat-box">
        {messages.map((msg, idx) => (
          <div
            key={idx}
            className={`message ${msg.sender === "user" ? "user" : "ai"}`}
          >
            {msg.content}
          </div>
        ))}
        {/* Loading indicator when waiting for AI response */}
        {isLoading && (
          <div className="message ai" aria-live="polite">
            <em>AI is typing...</em>
          </div>
        )}
        <div ref={chatEndRef} />
      </section>

      {error && (
        <div style={{ padding: "0.5rem 1rem", color: "red", textAlign: "center" }}>
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="input-bar">
        <input
          type="text"
          aria-label="Type your message"
          value={userInput}
          onChange={(e) => setUserInput(e.target.value)}
          placeholder="Type a message..."
        />
        <button type="submit" aria-label="Send message">
          ➤
        </button>
      </form>
    </main>
  );
}

export default App;

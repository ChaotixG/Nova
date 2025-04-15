use std::process::{Command, Stdio};
use std::path::{Path};
use std::io::{self, Read, Error};
use tauri::{Emitter};
use serde::Deserialize;

#[derive(Deserialize)]
struct NovaConfig {
    name: String,
    description: String,
    tone: String,
    directives: Vec<String>,
    nsfw_policy: String,
    censorship: String,
    disclaimer_policy: String,
    tagline: String,
    response_directive: String,
}


pub struct LlamaModel {
    model_path: String,
    model_prompt: String,
}

impl LlamaModel {
    pub fn load(model_path: &Path, prompt_path: &Path) -> Result<Self, Error> {
        if model_path.exists() {
            // Read the prompt config file
            let prompt_contents = std::fs::read_to_string(prompt_path)
                .map_err(|_| io::Error::new(io::ErrorKind::NotFound, "Prompt file not found"))?;
            
            // Deserialize JSON into NovaConfig
            let config: NovaConfig = serde_json::from_str(&prompt_contents)
                .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, format!("Failed to parse JSON: {}", e)))?;
            
            // Build the prompt string. You can customize this as needed.
            let model_prompt = format!(
                "{}\n{}\n\n- {}\n{}\n{}\n{}\n{}\n{}",
                config.description,
                config.tone,
                config.directives.join("\n- "),
                format!("nsfw_policy{}", config.nsfw_policy),
                config.censorship,
                config.disclaimer_policy,
                config.tagline,
                config.response_directive
            );
            
            Ok(Self {
                model_path: model_path.to_string_lossy().to_string(),
                model_prompt,
            })
        } else {
            Err(io::Error::new(io::ErrorKind::NotFound, "Model not found"))
        }
    }
    

    // Inference method
    pub fn run_inference(&mut self, prompt: &str) -> Result<String, Error> {
        let combined = format!("{}\n\n{}", self.model_prompt, prompt);
        print!("Inferrence on: {}\n", combined);  // Debugging
    
        let output = Command::new("./../llama.cpp/build/bin/release/llama-cli.exe")
            .args(&[
                "-m", &self.model_path,
                "-p", &combined,
                "--temp", "0.7",
                "--n-predict", "256",
                "--top_p", "0.95",
                "--top_k", "40",
                "--repeat_penalty", "1.1",
                "--repeat_last_n", "64",
            ])
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()?;
    
        if output.status.success() {
            let raw_output = String::from_utf8_lossy(&output.stdout).to_string();
    
            // Find and remove the prompt section
            if let Some(pos) = raw_output.find(&prompt) {
                // Take everything after the user's prompt
                let reply = &raw_output[(pos + prompt.len())..];
                Ok(reply.trim_start().to_string())
            } else {
                // Fallback — if prompt not found, return whole output
                Ok(raw_output)
            }
        } else {
            let stderr = String::from_utf8_lossy(&output.stderr);
            Err(io::Error::new(io::ErrorKind::Other, format!("LLM process failed: {}", stderr)))
        }
    }
    
    
    // Streaming method — emits full output as-is
pub fn run_llm_stream(&mut self, prompt: String, app_handle: tauri::AppHandle) -> Result<(), String> {
    let combined = format!("{}\n\n{}", self.model_prompt, prompt);
    println!("Stream on: {}\n", combined);

    let mut child = Command::new("./../llama.cpp/build/bin/release/llama-cli.exe")
        .args(&[
            "-m", &self.model_path,
            "-p", &combined,
            "--temp", "0.70",
            "--n-predict", "512",
            "--top_p", "0.98",
            "--top_k", "40",
            "--repeat_penalty", "1.1",
            "--repeat_last_n", "64",
        ])
        .stdout(Stdio::piped())
        .spawn()
        .map_err(|e| format!("Failed to start LLM process: {}", e))?;

    let mut stdout = child.stdout.take().ok_or("Failed to capture stdout")?;
    let mut buffer = [0; 64];

    loop {
        let bytes_read = stdout.read(&mut buffer).map_err(|e| e.to_string())?;
        if bytes_read == 0 {
            break;
        }

        let chunk = String::from_utf8_lossy(&buffer[..bytes_read]).to_string();

        // Emit every chunk directly — no prompt skipping
        app_handle.emit("stream_chunk", chunk)
            .map_err(|e| format!("Failed to emit chunk: {}", e))?;
    }

    let status = child.wait()
        .map_err(|e| format!("Failed to wait for LLM process: {}", e))?;

    if status.success() {
        Ok(())
    } else {
        Err("LLM process exited with error".to_string())
    }
}

    
}

// Initialize the LlamaModel
pub fn initialize_model() -> Result<LlamaModel, io::Error> {
    let model_path = Path::new("./../src/assets/models/mistral-7b-uncensored.gguf");
    let prompt_path = Path::new("./../src/settings/personalities/nova_unfiltered_prompt.json");
    LlamaModel::load(model_path, prompt_path)
}



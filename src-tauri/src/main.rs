use std::process::{Command, Stdio};
use std::io::{self, Read, BufRead, BufReader}; // Add Read here

mod db;
mod llm; // Ensure the llm module is correctly imported

#[tauri::command]
fn send_prompt(prompt: String) -> String {
    match llm::run_llm(&prompt) {
        Ok(response) => response,
        Err(e) => format!("Error: {}", e),
    }
}

#[tauri::command]
async fn run_inference(prompt: String) -> Result<String, String> {
    let prompt_clone = prompt.clone();
    tokio::task::spawn_blocking(move || {
        match llm::initialize_model() {
            Ok(mut model) => {
                let output = model.run_inference(&prompt).map_err(|e| e.to_string())?;
                // Remove the prompt from the output if it appears at the start
                let cleaned_output = output.strip_prefix(&prompt_clone)
                                           .unwrap_or(&output)
                                           .trim_start()
                                           .to_string();
                Ok(cleaned_output)
            }
            Err(e) => Err(e.to_string()),
        }
    })
    .await
    .map_err(|e| e.to_string())?
}


#[tauri::command]
async fn run_llm_stream(prompt: String, app_handle: tauri::AppHandle) -> Result<(), String> {
    tokio::task::spawn_blocking(move || {
        match llm::initialize_model() {
            Ok(mut model) => model.run_llm_stream(prompt, app_handle),
            Err(e) => Err(e.to_string()),
        }
    })
    .await
    .map_err(|e| e.to_string())?
}




fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![send_prompt, run_inference, run_llm_stream])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

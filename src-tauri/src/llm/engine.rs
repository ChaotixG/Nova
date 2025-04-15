use std::process::Command;
use std::str;
use std::io;

pub fn run_llm_engine(prompt: &str) -> Result<String, io::Error> {
    let llama_executable = "./../llama.cpp/build/bin/release/llama-cli.exe";  // Adjusted relative path to binary
    let model_path = "./../src/assets/models/dragon-mistral-7b-v0.Q8_0.gguf"; // Adjust model path

    let output = Command::new(llama_executable)
        .arg("--model")
        .arg(model_path)
        .arg("--prompt")
        .arg(prompt)
        .arg("--n-predict")
        .arg("512")
        .output();

    match output {
        Ok(result) if result.status.success() => Ok(String::from_utf8_lossy(&result.stdout).to_string()),
        Ok(result) => {
            eprintln!("LLM process failed: {}", String::from_utf8_lossy(&result.stderr));
            Err(io::Error::new(io::ErrorKind::Other, "LLM process failed"))
        },
        Err(e) => {
            eprintln!("Failed to execute llama.cpp process: {}", e);
            Err(e)
        }
    }
}
 
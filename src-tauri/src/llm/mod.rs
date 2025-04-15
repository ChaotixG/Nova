pub mod engine;
pub mod model;
pub mod types;

pub use engine::run_llm_engine;
pub use model::initialize_model;
use std::error::Error;

pub fn run_llm(prompt: &str) -> Result<String, Box<dyn Error>> {
    match engine::run_llm_engine(prompt) {
        Ok(response) => Ok(response),
        Err(e) => Err(Box::new(e)),
    }
}

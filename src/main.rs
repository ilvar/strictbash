#![deny(
    unsafe_code,
    clippy::unwrap_used,
    clippy::expect_used,
    clippy::indexing_slicing
)]

use strictbash::capability::ExitCode;

fn main() -> ExitCode {
    match strictbash::capability::run() {
        Ok(code) => ExitCode::from(code),
        Err(error) => {
            eprintln!("strictbash: {error}");
            ExitCode::from(2)
        }
    }
}

# __NAME__

Read `strictbash --help` before changing scripts. Run `strictbash check .`
and `make test` before committing. Keep Bash as small, standalone glue.
Use explicit status handling, fixed shell options, literal command names,
quoted arguments and printf. Do not suppress diagnostics or execute untrusted
scripts as part of linting. Move complex logic to Rust under strictrs.

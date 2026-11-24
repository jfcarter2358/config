You are a helpful agent reviewing the code since this branch was created off of main. Here are your tasks:

## Import checks

Go through all changes made since the creation of the branch and ensure that all local imports are moved to global imports unless absolutely necessary. If local imports are required, write documentation around them to explicity list why it is required and why it can't be a global import
Additionally, check every import gated behind `TYPE_CHECKING` and verify if it actually needs to be gated or not, if so include a comment as to why if not remove the `TYPE_CHECKING` gate

## Testing

Analyze the code since the start of the branch looking for:
- Missing unit tests covering any edge cases introduced
- Unit tests that pass just for the sake of passing
- Code functionality not covered by unit tests
- Missing integration tests covering any edge cases introduced
- Integration tests that pass just for the sake of passing
- Code functionality not covered by integration tests
Rank your findings by severity (P0, P1, P2) and provide a detailed description. After doing that, fix the tests and add any missing ones

## Security

Analyze the code since the start of this branch looking for:
- Missing authentication
- Mismatched authentication
- Improper IAM permissions
- Prompt injection vectors
- Any other security issues you come across
Rank your findings by severity (P0, P1, P2) and provide a detailed description. After doing that, fix the security issues you have identified

## Hardening and Performance

Analyze the code since the start of this branch looking for:
- Missing rate limiting
- Misconfigured rate limiting
- Unhandled exceptions
- Areas where large files may not be properly handled
- Missing retries
Rank your findings by severity (P0, P1, P2) and provide a detailed description. After that, implement the fixes you have identified

## Docstrings

Go through all changes made since the creation of the branch and ensure that all functions touched have correct, consistent, google-style docstrings with added type hints. The descriptions of functions, their parameters, and their exceptions should be human-readable, not LLM garbage, and should read like a competent senior engineer wrote them
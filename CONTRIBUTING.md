# Contributing to GameVerse NFT Protocol

First off, thank you for considering contributing to GameVerse NFT Protocol! It's people like you that make GameVerse such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the issue list as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* Use a clear and descriptive title
* Describe the exact steps which reproduce the problem
* Provide specific examples to demonstrate the steps
* Describe the behavior you observed after following the steps
* Explain which behavior you expected to see instead and why
* Include screenshots if possible

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* Use a clear and descriptive title
* Provide a step-by-step description of the suggested enhancement
* Provide specific examples to demonstrate the steps
* Describe the current behavior and explain which behavior you expected to see instead
* Explain why this enhancement would be useful

### Pull Requests

* Fill in the required template
* Do not include issue numbers in the PR title
* Include screenshots and animated GIFs in your pull request whenever possible
* Follow the Clarity style guide
* Include thoughtfully-worded, well-structured tests
* Document new code
* End all files with a newline

## Smart Contract Development Guidelines

### Writing Clarity Code

* Use meaningful variable and function names
* Comment your code thoroughly
* Follow the principle of least privilege
* Always include proper error handling
* Test thoroughly before submitting

### Testing

* Write comprehensive tests for all new functions
* Include both positive and negative test cases
* Test edge cases thoroughly
* Ensure all tests pass before submitting

## Development Process

1. Fork the repo
2. Create a new branch
3. Make your changes
4. Write or update tests
5. Update documentation
6. Submit a pull request

## Style Guide

### Clarity Code Style

```clarity
;; Good
(define-public (transfer-asset (token-id uint) (recipient principal))
  (begin
    ;; Check authorization
    (asserts! (is-owner token-id tx-sender) ERR-NOT-AUTHORIZED)
    ;; Perform transfer
    (nft-transfer? gameverse-asset token-id tx-sender recipient)
  )
)

;; Bad
(define-public (transferAsset (tokenId uint) (recipient principal))
  (nft-transfer? gameverse-asset tokenId tx-sender recipient)
)
```

## Questions?

Feel free to open an issue with your question or contact the maintainers directly.
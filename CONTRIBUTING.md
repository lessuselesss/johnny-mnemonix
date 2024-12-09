# Contributing to Johnny-Mnemonix

Thank you for your interest in contributing to Johnny-Mnemonix! This document provides guidelines and information for contributors.

## Code of Conduct

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by its terms.

## Getting Started

1. **Fork the Repository**
   ```bash
   git clone https://github.com/lessuselesss/johnny-mnemonix.git
   cd johnny-mnemonix
   ```

2. **Set Up Development Environment**
   ```bash
   # Enter development shell
   nix develop
   ```

3. **Make Your Changes**
   - Write clear, concise commit messages
   - Follow the existing code style
   - Add tests for new features
   - Update documentation as needed

## Development Guidelines

### Code Style

- Follow the Nixpkgs coding style
- Use meaningful variable names
- Add comments for complex logic
- Keep functions focused and small

### Commit Messages

Format:
```
type(scope): description

[optional body]
[optional footer]
```

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation changes
- style: Formatting changes
- refactor: Code restructuring
- test: Adding tests
- chore: Maintenance tasks

### Testing

1. **Run Tests**
   ```bash
   nix flake check
   ```

2. **Test Configuration**
   ```bash
   home-manager build -I johnny-mnemonix=.
   ```

### Documentation

- Update README.md for user-facing changes
- Add/update documentation in docs/
- Include examples for new features
- Document breaking changes

## Pull Request Process

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Follow development guidelines
   - Keep changes focused
   - Test thoroughly

3. **Submit Pull Request**
   - Describe changes clearly
   - Reference related issues
   - Update documentation
   - Add tests if needed

4. **Review Process**
   - Address review comments
   - Keep discussion focused
   - Be patient and respectful

## Release Process

1. **Version Bumping**
   - Update version in flake.nix
   - Update CHANGELOG.md
   - Create release notes

2. **Testing**
   - Verify all tests pass
   - Check documentation
   - Test installation process

3. **Release**
   - Tag release in git
   - Update documentation
   - Announce changes

## Getting Help

- Open an issue for questions
- Join community discussions
- Read existing documentation

Thank you for contributing to Johnny-Mnemonix!
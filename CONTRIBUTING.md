# Contributing to Sebae

Thank you for your interest in contributing to Sebae! Here are some guidelines to help you get started.

## 📌 How to Contribute

### Reporting Bugs
- Open an Issue on GitHub with a clear description of the problem.
- Include steps to reproduce the bug.
- Add screenshots if applicable.

### Suggesting Features
- Open an Issue with your feature request.
- Describe the use case and why it would be useful.

### Submitting Changes
1. Fork the repository.
2. Create a feature branch: git checkout -b feature/my-feature
3. Make your changes and commit them: git commit -m 'Add my feature'
4. Push to your fork: git push origin feature/my-feature
5. Open a Pull Request on GitHub.

## 🛠️ Development Setup

1. Clone the repository:
   git clone https://github.com/CharlieG42/Sebae.git

2. Create a virtual environment:
   python -m venv venv
   source venv/bin/activate  # or venvScriptsactivate on Windows

3. Install development dependencies:
   pip install -r requirements.txt
   pip install pytest pytest-qt

4. Run tests:
   pytest tests/ -v

## 📝 Code Style

- Follow PEP 8 guidelines.
- Use descriptive variable and function names.
- Add docstrings to all public functions and classes.
- Keep functions short and focused.

## 🧪 Testing

- All new features should include unit tests.
- Tests should be placed in the tests/ directory.
- Run tests before submitting a Pull Request.

## 📄 Commit Messages

- Use clear, descriptive commit messages.
- Follow the convention: type(scope): description
- Example: feat(core): add pump efficiency validation

## 🎉 Pull Request Process

1. Ensure all tests pass.
2. Update the README.md if needed.
3. Keep your PR focused on a single feature or bug fix.
4. Be responsive to feedback and make requested changes.

## 🙏 Code of Conduct

Be respectful and inclusive. Follow the Python Community Code of Conduct.
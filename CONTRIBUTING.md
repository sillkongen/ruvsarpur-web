# Contributing to RÚV Sarpurinn Web Downloader

Thank you for your interest in contributing to this project! We welcome contributions from everyone.

## 🚀 Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/sillkongen/ruvsarpur-web.git
   cd ruvsarpur-web
   ```
3. **Create a branch** for your feature:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 🛠️ Development Setup

### Prerequisites

- Python 3.9+
- Docker and Docker Compose (for testing)
- Access to ruvsarpur source code

### Local Development

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Setup EPG data:**
   ```bash
   ./setup-epg.sh
   ```

3. **Start the development servers:**
   ```bash
   # Terminal 1 - Backend
   cd backend
   uvicorn app.main:app --reload --workers 1 --port 8001
   
   # Terminal 2 - Frontend
   python app.py
   ```

### Docker Development

```bash
docker-compose up --build
```

## 📝 Code Style

- Follow PEP 8 for Python code
- Use meaningful variable and function names
- Add docstrings for new functions and classes
- Keep functions focused and small

## 🧪 Testing

Before submitting a PR:

1. **Test the application manually:**
   - Search functionality
   - Download process
   - UI responsiveness
   - Dark mode toggle

2. **Test with Docker:**
   ```bash
   docker-compose up --build
   ```

3. **Check logs for errors:**
   ```bash
   docker-compose logs
   ```

## 📋 Pull Request Process

1. **Update documentation** if needed
2. **Ensure your PR description** clearly describes the problem and solution
3. **Link any relevant issues**
4. **Test your changes** thoroughly
5. **Make sure your commits** have clear, descriptive messages

### PR Checklist

- [ ] Code follows the project's style guidelines
- [ ] Self-review of the code has been done
- [ ] Changes have been tested locally
- [ ] Documentation has been updated if necessary
- [ ] No new warnings or errors are introduced

## 🐛 Bug Reports

When filing an issue, please include:

1. **Operating System** and version
2. **Python version**
3. **Docker version** (if using Docker)
4. **Steps to reproduce** the issue
5. **Expected behavior**
6. **Actual behavior**
7. **Logs or error messages**

## 💡 Feature Requests

We welcome feature requests! Please:

1. **Check existing issues** to avoid duplicates
2. **Describe the feature** in detail
3. **Explain the use case** and why it would be valuable
4. **Consider the scope** - smaller, focused features are easier to implement

## 🔄 Areas for Contribution

### Frontend Improvements
- UI/UX enhancements
- Mobile responsiveness
- Accessibility improvements
- Performance optimizations

### Backend Features
- API improvements
- Better error handling
- Performance optimizations
- Additional download options

### DevOps & Infrastructure
- CI/CD pipeline improvements
- Docker optimizations
- Documentation updates
- Testing improvements

### Integration Features
- Better ruvsarpur integration
- Additional metadata support
- Search improvements
- Download management features

## 📚 Project Architecture

```
ruvsarpur-web/
├── app.py              # Flask frontend
├── backend/app/main.py # FastAPI backend
├── database.py         # SQLite operations
├── templates/          # HTML templates
├── static/             # CSS, JS, assets
└── docker-compose.yml  # Container orchestration
```

### Key Components

- **Flask Frontend**: Serves web interface, handles user interactions
- **FastAPI Backend**: Provides API endpoints, manages downloads
- **SQLite Database**: Tracks download history and status
- **ruvsarpur Integration**: Calls the original script for downloads

## 🤝 Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help newcomers get started
- Maintain a positive environment

## 📞 Getting Help

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion

Thank you for contributing! 🙏 
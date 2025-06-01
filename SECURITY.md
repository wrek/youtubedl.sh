# Security Policy

## Supported Versions

Currently supported versions of this YouTube downloader:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please follow these steps:

### How to Report
1. **Do NOT** create a public GitHub issue for security vulnerabilities
2. Email the maintainer directly at: generalchad@gmail.com
3. Include "SECURITY" in the subject line
4. Provide detailed information about the vulnerability

### What to Include
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Any suggested fixes (if you have them)
- Your contact information for follow-up

### Response Timeline
- **24-48 hours**: Initial acknowledgment of your report
- **1 week**: Initial assessment and triage
- **2-4 weeks**: Fix development and testing (depending on complexity)
- **Upon fix**: Coordinated disclosure and credit (if desired)

### Scope
This security policy covers:
- The main PowerShell script (`youtube-dl.ps1`)
- Configuration handling
- File system operations
- External command execution

### Out of Scope
- Third-party dependencies (yt-dlp, youtube-dl)
- YouTube's services or infrastructure
- Issues with downloaded content

### Security Best Practices for Users
- Run the script in a sandboxed environment when possible
- Avoid running with elevated privileges unless necessary
- Keep yt-dlp/youtube-dl updated to the latest versions
- Be cautious with URLs from untrusted sources
- Review downloaded content before opening

## Acknowledgments
We appreciate responsible disclosure of security vulnerabilities and will acknowledge contributors (with their permission) in our security advisories.

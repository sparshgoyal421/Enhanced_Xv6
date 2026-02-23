# Changelog

All notable changes to Enhanced Xv6 will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive documentation suite
- API reference documentation
- Performance profiling guide
- Security best practices guide
- Glossary of terms
- FAQ documentation
- Examples and tutorials

## [1.5.0] - 2026-02-11

### Added
- User management system with database utilities
- Test scripts for user operations
- Enhanced error handling in user programs

### Changed
- Improved file organization
- Updated README with better project description

### Fixed
- Minor bug fixes in user utilities

## [1.0.0] - 2024-12-10

### Added
- Copy-on-Write (COW) fork implementation
- Demand paging with page fault handling
- Lazy allocation for heap and stack
- Memory-mapped files (mmap/munmap)
- Enhanced buffer cache
- Extended system call interface
- Improved shell with command history
- Background process execution
- I/O redirection (pipes, redirects)
- Basic tab completion

### Changed
- Migrated from x86 to RISC-V architecture
- Upgraded to SV39 paging mode
- Refactored memory management
- Improved scheduler design

### Fixed
- Race conditions in fork implementation
- Memory leaks in file operations
- Page table corruption issues

## [0.9.0] - 2024-09-15

### Added
- Initial RISC-V port
- Basic process management
- Simple file system
- System call interface
- Shell implementation
- Device drivers (UART, disk)

### Changed
- Ported from original xv6-x86
- Updated build system for RISC-V
- Adapted memory layout for SV39

## Types of Changes

- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for vulnerability fixes

## Version History

### Version 1.5.x - User Management & Documentation
Focus on user utilities, database management, and comprehensive documentation.

### Version 1.0.x - Enhanced Features
Major feature additions including COW fork, demand paging, and improved shell.

### Version 0.9.x - Initial RISC-V Port
Basic functionality ported from x86 to RISC-V.

## Upcoming Features

See [roadmap.md](docs/roadmap.md) for planned features.

### Version 2.0 (Planned - Q2 2026)
- Multi-level feedback queue scheduler
- Journaling file system
- Enhanced security features
- Comprehensive test suite
- Network stack basics

### Version 2.5 (Planned - Q4 2026)
- Full networking support
- Improved multi-core support
- Advanced shell features
- Developer tools suite

### Version 3.0 (Planned - Q2 2027)
- Virtual file system layer
- Container support
- USB device support
- Production-grade stability

## Migration Guides

### Upgrading from 0.9.x to 1.0.0

**Breaking Changes:**
- System call numbers changed
- Memory layout modified for COW
- Shell command syntax updated

**Migration Steps:**
1. Rebuild all user programs
2. Update any custom system calls
3. Review and update memory allocation code

### Upgrading from 1.0.x to 1.5.0

**Changes:**
- New user management utilities
- Extended file operations
- Database support added

**Migration Steps:**
1. No breaking changes
2. Update documentation references
3. Review new utilities for potential use

## Contributing

See [CONTRIBUTING.md](docs/contributing.md) for guidelines on contributing to Enhanced Xv6.

## Release Process

1. Update version numbers
2. Update CHANGELOG.md
3. Tag release in git
4. Build and test
5. Push to repository
6. Create GitHub release

## Support

- **Issues**: Report bugs via GitHub Issues
- **Discussions**: Join community discussions
- **Documentation**: See [docs/](docs/) directory

## Acknowledgments

Enhanced Xv6 is built upon the original xv6 operating system developed at MIT. We thank the xv6 authors and contributors for their excellent educational OS.

---

For detailed commit history, see `git log` or the GitHub repository.

## 1.2.2 - 2026-09-15
### Fixed
- Release metadata for the corrected pub.dev publishing workflow

## 1.2.1 - 2026-09-15
### Fixed
- Relaxed the `analysis_server_plugin` constraint so `meovm_lint` passes pub.dev validation

## 1.2.0 - 2026-09-14
### Added
- Code generation for generic ViewModels and parameters, including bounded and nullable type
  parameters (#44)

### Fixed
- Dependency discovery through generic, getter-backed, nested, and external member accessors (#44)

## 1.1.3 - 2025-12-12
### Fixed
- RiverpodActionGroup initialization (#37)

## 1.1.2 - 2025-12-09
### Fixed
- Updated build & source\_gen versions to actual

## 1.1.1 - 2025-12-09
### Fixed
- Scoped VM retrieval order — [\#33](https://github.com/da-cat7976/meovm/issues/33)

## 1.1.0 - 2025-09-22
### Added
- Custom linter:
  - External modification lint for members
  - Lifecycle methods use for members and VMs
  - Abstract resolvers
- Supertype-safe VM & param retrieval

### Fixed
- Typos in README.md

### Removed
- Experiments:
  - ViewModelDelegate
  - MemberGroup

## 1.0.0 - 2025-09-17
### Added
- High-level API
- Extensible ViewModelOwner implementation
- Pack of necessary members
- Code generation for VMs & params
- Integration package for flutter\_bloc
- Integration package for riverpod

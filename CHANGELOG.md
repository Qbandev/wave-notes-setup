# Changelog

## [2.0.2](https://github.com/Qbandev/wave-notes-setup/compare/v2.0.1...v2.0.2) (2026-02-12)


### Bug Fixes

* add swap token exchange for Wave Terminal v0.14.0+ ([65d7666](https://github.com/Qbandev/wave-notes-setup/commit/65d7666817510a85a56efd437dc601a3ac08374e))
* add swap token exchange for Wave Terminal v0.14.0+ compatibility ([94c016f](https://github.com/Qbandev/wave-notes-setup/commit/94c016fd46701c8b9fa192db1a47f11db70d1963))
* remove redundant WSH_CMD check, use printf over echo for safety ([a5a57fb](https://github.com/Qbandev/wave-notes-setup/commit/a5a57fb7cb2e6026e50df78cbe940a6f0a338936))
* replace eval with direct JWT parsing in swap token exchange ([604620a](https://github.com/Qbandev/wave-notes-setup/commit/604620a7787c9c0fa6c1b2efd3abc3156eeaa403))
* revert to eval for wsh token exchange ([bb9279f](https://github.com/Qbandev/wave-notes-setup/commit/bb9279f126881f0c44db1c6ca2f0b15cd10e1dd1))

## [2.0.1](https://github.com/Qbandev/wave-notes-setup/compare/v2.0.0...v2.0.1) (2026-02-04)


### Bug Fixes

* add default value for validate_safe_path name parameter ([5ace831](https://github.com/Qbandev/wave-notes-setup/commit/5ace8316df02316b040ea788514705593e1eadb0))
* address code review findings ([626261e](https://github.com/Qbandev/wave-notes-setup/commit/626261e8a97a87cff302c166101f563238ab3797))
* address remaining Copilot review comments ([a485869](https://github.com/Qbandev/wave-notes-setup/commit/a485869151e0326492c8026f7e0954747889c245))
* **chore:** update install.sh comment ([18e7421](https://github.com/Qbandev/wave-notes-setup/commit/18e7421780f927f4402b0ad3445340a1426cf46c))
* **security:** add Downloads to protected directories in uninstall.sh ([68251af](https://github.com/Qbandev/wave-notes-setup/commit/68251af0ac23fde32a6475c21887cad2fe00800a))
* **security:** address Copilot review feedback ([87812fa](https://github.com/Qbandev/wave-notes-setup/commit/87812fa55a4a353850ee099ccf2302e307cb7ae0))
* **security:** address vulnerabilities from security audit ([8bf9fe7](https://github.com/Qbandev/wave-notes-setup/commit/8bf9fe70a68a119eaec9deeb8086bd077db52d07))
* **security:** address vulnerabilities from security audit ([5f1a15f](https://github.com/Qbandev/wave-notes-setup/commit/5f1a15f43c4748afd0b3929ef9547f9c7cb898f4))
* **security:** block Library subdirectories in install.sh ([2ec048d](https://github.com/Qbandev/wave-notes-setup/commit/2ec048d22f859c3dbc9905c1f2e5705b2fe32914))
* **security:** reject shell metacharacters in paths ([230e38b](https://github.com/Qbandev/wave-notes-setup/commit/230e38b41b5ff91e080ef8eadf4f4bea6bedce45))
* **security:** sync security functions and add missing checks ([a52bfaf](https://github.com/Qbandev/wave-notes-setup/commit/a52bfaf8606805d0f8215dcdc62e4023b3b30882))

## [2.0.0](https://github.com/Qbandev/wave-notes-setup/compare/v1.0.1...v2.0.0) (2026-02-03)


### ⚠ BREAKING CHANGES

* The installer now only creates a single "note" widget. The "All Notes" directory browser widget (custom:notes-list) has been removed.

### Features

* remove "All Notes" widget, rename to single "note" widget ([c0ed10d](https://github.com/Qbandev/wave-notes-setup/commit/c0ed10de94cac8e82e2aceef41543ce8e5dc0e34))


### Bug Fixes

* address Copilot review feedback ([b3d468b](https://github.com/Qbandev/wave-notes-setup/commit/b3d468b0da475598d300885c97aef698b9348b39))
* consistent info message format and test assertion ([ef960d1](https://github.com/Qbandev/wave-notes-setup/commit/ef960d13e1c5f64d24840bb91c4959312854c644))

## [1.0.1](https://github.com/Qbandev/wave-notes-setup/compare/v1.0.0...v1.0.1) (2026-02-02)


### Bug Fixes

* **ci:** add issues write permission for Homebrew reminder ([3d4e838](https://github.com/Qbandev/wave-notes-setup/commit/3d4e83849eb170111045b68113f3ff1b4ea65a8a))

## 1.0.0 (2026-02-02)


### ⚠ BREAKING CHANGES

* **install:** Installation now requires Wave Terminal to be installed first

### Features

* add GitHub workflow automation ([e0e7405](https://github.com/Qbandev/wave-notes-setup/commit/e0e74050131188a49cdcec36691a991a70f4f9fd))
* **install:** add Wave detection, JSON validation, and release automation ([899b5b8](https://github.com/Qbandev/wave-notes-setup/commit/899b5b8170790c72a7269b1926a4e4778735229b))
* **install:** add Wave detection, JSON validation, and release automation ([a406801](https://github.com/Qbandev/wave-notes-setup/commit/a406801e09584d818822013ed1ff467cfc0f0049))


### Bug Fixes

* address additional code review feedback ([eb14219](https://github.com/Qbandev/wave-notes-setup/commit/eb14219d7a05da1403a00f5491ee09dd43c9abcf))
* address code review feedback ([2fa0191](https://github.com/Qbandev/wave-notes-setup/commit/2fa01914e28fdbc23cd0b9db0d5a8d5cb10c5468))
* address code review issues and improve error handling ([f6f4d11](https://github.com/Qbandev/wave-notes-setup/commit/f6f4d111719dd246b03748707382b90a2133346d))
* **ci:** fix YAML syntax in release-please workflow ([feabd28](https://github.com/Qbandev/wave-notes-setup/commit/feabd28ebae42cb78281b3f45bbd6ee3128cdbb5))
* **ci:** remove invalid package-name input from release-please ([1d059a3](https://github.com/Qbandev/wave-notes-setup/commit/1d059a3cbcc377155877f4ff6f2b1e32c5591e68))

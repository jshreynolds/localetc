# Manual Setup Steps Required

After running the automated installation, the following manual steps are required:

## System Preferences

- [ ] **FileVault**: System Preferences → Security & Privacy → FileVault → Turn On
- [ ] **Touch ID**: System Preferences → Touch ID → Add fingerprints
- [ ] **Internet Accounts**: System Preferences → Internet Accounts → Add accounts

## Security & Privacy

- [ ] **Full Disk Access**: Grant to Terminal, VS Code, and other dev tools
- [ ] **Developer Tools**: Allow terminal apps in Security preferences
- [ ] **Firewall**: Enable firewall with stealth mode

## Applications

### Essential Apps
- [ ] **1Password**: Sign in and configure browser extensions
- [ ] **Dropbox/iCloud**: Set up file sync
- [ ] **VS Code**: Sign in to enable Settings Sync

### Development
- [ ] **GitHub**: Generate personal access token for CLI
- [ ] **GPG Keys**: Import or generate new GPG keys for commit signing
- [ ] **SSH Keys**: Add SSH key to GitHub/GitLab/etc
- [ ] **AWS Credentials**: Configure with `aws configure`
- [ ] **Docker Desktop**: Sign in to Docker Hub (if using)

### Communication
- [ ] **Slack**: Sign in to workspaces
- [ ] **Zoom**: Sign in and configure settings
- [ ] **Discord**: Sign in to servers

## App Store

Some apps must be installed from the App Store:
- [ ] Xcode (if doing iOS development)
- [ ] Any purchased apps not available via Homebrew

## Browser

- [ ] **Extensions**: Install password manager, ad blocker, etc.
- [ ] **Bookmarks**: Import or sync bookmarks
- [ ] **Search Engine**: Set preferred search engine

## Terminal

- [ ] **Alacritty**: Verify configuration is loaded
- [ ] **Shell**: Confirm zsh is default shell
- [ ] **Fonts**: Verify Nerd Fonts are rendering correctly

## Final Steps

- [ ] **Reboot**: Restart to ensure all changes take effect
- [ ] **Verify**: Run `etc-status` to check configuration
- [ ] **Backup**: Create Time Machine backup of configured system
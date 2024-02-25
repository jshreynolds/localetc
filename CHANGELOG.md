## 0.2.0 (2024-02-25)

### Feat

- add commitizen conventional commit structure.  enable direnv-asdf

## 0.1.0 (2024-02-25)

### Feat

- adding in a bit more polish
- migrating project initialization helper scripts
- add more componentization and refactor to allow permissions for setting safari and mail preferences
- add ability to add the latest asdf package and set it's version as the globally available one.
- add k8s lense
- drop oh-my-zsh and add starship for dope prompt.  shift to lsd

### Fix

- organizaing tsconfig.json
- add deno to the set of asdf managed binaries. add manual apps for syncing. refactor brewfile for clarity.
- cleanup legacy README, remove unused software and stop serializaing old zellij
- setting shell to bash
- lots of small syntax improvements.  prune unused packages from Brewfile
- removing direnv-asdf as it seemed a bit too complicated for my needs
- ignoring binary built hackersplat
- cleaning up unnecessary alacritty theme installation.  just version controlling a copy of the theme I want for now
- minor ergo tweaks
- cleanup
- readded zsh-syntax-highlighting
- some tweaks to start using zellij config with copy/paste that works for macos
- trimming some extraneous config of the conda environment
- add some command line query tools
- add dagger.io to the mix
- Add direnv and a few other items to the configuration
- add mmv to list of 'new' unix commands
- Update brewfile with commandline power tools

### Refactor

- move asdf selected software into dotfiles and source from there
- cleaning up zshrc and moving components to separate environment packages
- tweak config

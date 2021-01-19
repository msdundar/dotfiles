#!/usr/bin/env bash

set -e

info () {
  printf "\r[ \033[00;34m\u221E INFO\033[0m ] %s\n" "$1"
}

success () {
  printf "\r\033[2K[ \033[00;32m\xE2\x9C\x94 OK\033[0m   ] %s\n" "$1"
}

warning () {
  printf "\r\033[2K[ \033[0;31m\u2718 FAIL\033[0m ] %s\n" "$1"
}

fail () {
  printf "\r\033[2K[ \033[0;31m\u2718 FAIL\033[0m ] %s\n" "$1"
  echo ''
  exit
}

set_variables(){
  info 'Detecting system information...'

  if [ "$(uname -s)" == "Darwin" ]
  then
    OPERATING_SYSTEM=OSx
  else
    OPERATING_SYSTEM=Linux
  fi

  USER_NAME=$(whoami)

  if ! [ $OPERATING_SYSTEM == "OSx" ]
  then
    fail "Currently this script only supports OSx!"
  else
    success "OS detected: $OPERATING_SYSTEM"
    success "Username detected: $USER_NAME"
  fi
}

install_xcode(){
  xcode-select --install
}

install_brew(){
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
}

install_brewfile(){
  BREW_PREFIX=$(brew --prefix)

  info 'Installing some core libraries...'
  brew update && brew upgrade
  brew bundle
}

config_bash(){
  if ! grep -q "${BREW_PREFIX}/bin/bash" /etc/shells; then
    info 'Configuring bash...'
    echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells;
  fi;

  cp .bash_profile ~/
  success '.bash_profile configured successfully...'

  cp .bashrc ~/
  success '.bashrc configured successfully...'
}

config_zsh(){
  if ! grep -q "${BREW_PREFIX}/bin/zsh" /etc/shells; then
    info 'Configuring zsh...'
    echo "${BREW_PREFIX}/bin/zsh" | sudo tee -a /etc/shells;
  else
    success 'ZSH is already configured...'
  fi;

  if ! [ "$SHELL" == "/usr/local/bin/zsh" ]
  then
    info 'Setting zsh as default shell...'
    chsh -s /usr/local/bin/zsh
  else
    success 'zsh is already the default shell...'
  fi
}

install_iterm(){
  if ! [ "$TERM_PROGRAM" == 'iTerm.app' ]
  then
    info 'Installing iterm2...'
    brew cask install iterm2

    info 'Installing shell utilities for iterm'
    curl -L https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh | bash
  else
    success 'iTerm already installed...'
  fi

  cp etc/iterm_profile.json ~/Library/Application\ Support/iTerm2/DynamicProfiles/
  sed -i '' "s/OS_USER_NAME/$USER_NAME/" ~/Library/Application\ Support/iTerm2/DynamicProfiles/iterm_profile.json

  success 'iTerm2 configured successfully...'
}

config_git(){
  read -rp "Do you want to configure git? (N: No, Any Other Key: Yes): " prompt

  if [[ $prompt == "N" || $prompt == "n" ]]
  then
    info 'Skipping git configuration...'
  else
    cp .gitconfig ~/

    read -rp 'Git committer name: ' git_committer_name
    read -rp 'Git committer e-mail: ' git_committer_email

    sed -i '' "s/GIT_COMMITTER_NAME/$git_committer_name/" ~/.gitconfig
    sed -i '' "s/GIT_COMMITTER_EMAIL/$git_committer_email/" ~/.gitconfig

    echo "pinentry-program /usr/local/bin/pinentry-mac" >> ~/.gnupg/gpg-agent.conf

    success 'Git configured successfully!'
  fi
}

install_oh_my_zsh() {
  FOLDER="/Users/$USER_NAME/.oh-my-zsh"

  if [ -d "$FOLDER" ]; then
    success 'oh-my-zsh already installed...'
  else
    info 'Installing oh-my-zsh'
    sh -c "$(wget -O- https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

    info 'Installing oh-my-zsh themes...'
    git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
  fi
}

install_ruby() {
  TARGET_RUBY_VERSION=2.6.3

  if ! [ -x "$(command -v rbenv)" ]
  then
    info 'Configuring rbenv initializer...'
    rbenv init

    # shellcheck source=/dev/null
    source ~/.zshrc
  fi

  info 'Installing latest ruby version system-wide'
  FOLDER="/Users/$USER_NAME/.rbenv/versions/$TARGET_RUBY_VERSION"

  if [ -d "$FOLDER" ]; then
    success "Ruby $TARGET_RUBY_VERSION already installed..."
  else
    info "Installing ruby $TARGET_RUBY_VERSION"
    rbenv install $TARGET_RUBY_VERSION
  fi

  rbenv global $TARGET_RUBY_VERSION

  info 'Running rbenv doctor...'
  curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash

  info 'Installing irbtools...'
  gem install irbtools

  info 'Installing overcommit...'
  gem install overcommit

  cp .irbrc ~/
  success '.irbrc configured successfully...'

  cp .gemrc ~/
  success '.gemrc configured successfully...'

  cp .rspec ~/
  success '.rspec configured successfully...'
}

install_python(){
  brew install pyenv
  pyenv install 3.8.2
}

config_zshrc(){
  cp .zshrc ~/
  success '.zshrc configured successfully...'
}

config_gitigore(){
  cp .gitignore ~/
  success '.gitignore configured successfully...'
}

config_functions(){
  cp .functions ~/
  cat ~/.functions >> ~/.zshrc
  success '.functions configured successfully...'
}

config_howtos(){
  cp .howtos ~/
  cat ~/.howtos >> ~/.zshrc
  success '.howtos configured successfully...'
}

config_ssh(){
  cp .ssh/config ~/.ssh/
  success 'ssh config copied successfully...'
}

install_travis(){
  info 'Installing travisCLI...'
  gem install travis
}

install_pip(){
  if ! [ -x "$(command -v pip3)" ]
  then
    info 'Installing pip3...'
    curl -O https://bootstrap.pypa.io/get-pip.py
    python3 get-pip.py --user
  fi
}

install_aws(){
  if ! [ -x "$(command -v aws)" ]
  then
    info 'Installing aws-cli...'
    pip3 install awscli --upgrade --user
  fi
}

configure_aws(){
  info 'Configuring .aws client...'

  aws configure set default.region eu-west-1
  aws configure set default.output json

  aws configure set profile.personal.region eu-west-1
  aws configure set profile.personal.output json

  aws configure set profile.sandbox.region eu-west-1
  aws configure set profile.sandbox.output json

  info 'Configuring aws-sandbox account...'
  chmod +x ./bin/aws-sandbox.sh
  ./bin/aws-sandbox.sh
}

configure_vim(){
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

install_fonts(){
  mkdir -p "/Users/$USER_NAME/projects" && cd "$_"
  git clone git@github.com:tonsky/FiraCode.git
  cd FiraCode/
  ./script/bootstrap
  ./script/build
  ./script/install
}

update_packages(){
  softwareupdate --install --all
}

set_variables
install_xcode
install_brew
install_brewfile
config_bash
config_zsh
install_iterm
config_git
install_oh_my_zsh
install_ruby
config_zshrc
config_gitigore
config_functions
config_howtos
config_ssh
install_travis
install_pip
install_aws
configure_aws
install_fonts

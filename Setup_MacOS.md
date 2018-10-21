# Personal setup for MacOS

## Xcode

```bash
xcode-select --install
```

## Homebrew

### Install

```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)
```

### Packages

```bash
brew update 
brew install git htop neofetch openvpn tree iproute2mac
brew tap caskroom/cask
brew cask install iterm2 textmate google-chrome spectacle slack gimp mactex virtualbox vagrant vagrant-manager
```

## Shell

* ZSH
```bash
brew install zsh zsh-syntax-highlighting
```
* Oh-My-ZSH
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)
```
* Powerlevel9k + hack font
```bash
git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
brew tap caskroom/fonts
brew cask install font-hack-nerd-font
```
* Material design theme: installation instructions availables [here](https://github.com/MartinSeeler/iterm2-material-design)
```bash
wget https://raw.githubusercontent.com/MartinSeeler/iterm2-material-design/master/material-design-colors.itermcolors
```

## MacOS settings

```bash
scutil --set HostName
sudo scutil --set ComputerName <computer_name>
sudo scutil --set LocalHostName <computer_name>
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 1
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10
```

## Vim

### Install

```bash
brew install vim git
```

### Plugins

* Pathogen
```bash
mkdir -p ~/.vim/autoload ~/.vim/bundle
curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
```
* Vim-Airline
```bash
git clone https://github.com/vim-airline/vim-airline ~/.vim/bundle/vim-airline
```
* Vim-Airline themes
```bash
git clone https://github.com/vim-airline/vim-airline-themes ~/.vim/bundle/vim-airline-themes
```

## Python

### Install
* Python 3
```bash
brew install python
```
* Python 2.7
```bash
brew install python@2
```

### Pip
```bash
pip install --upgrade setuptools
pip install --upgrade pip
```

### iPython
```bash
pip install ipython
```

### Modules
```bash
pip install yara-python pycrypto pil
```

## Tools
```bash
brew install fcrackzip binwalk exiv2 exiftool foremost yara upx
```

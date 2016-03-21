#!/bin/bash
#
# To run this script, enter this into your terminal:
# bash -c "$(curl -fsSL https://gist.github.com/ryanmark/9ec33d5d4ee572f7853e/raw/setup-vox-middleman.sh)"
FAVORITE_RUBY=2.2.2

set -e

echo Setting up Vox Media Middleman rig.
echo

trap "exit 1" SIGINT;

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

if ! xcode-select -p >/dev/null 2>&1; then
  echo About to install Xcode tools. Please follow the instructions in the popup
  xcode-select --install
  echo
  echo "Once you've completed the Xcode install, press any key to continue"
  read -n 1 -s
fi

if ! hash brew 2>/dev/null; then
  echo
  echo Installing brew...
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

  echo 'export PATH=.bundle/bin:node_modules/.bin:/usr/local/bin:/usr/local/sbin:$PATH' >> ~/.bash_profile
  export PATH=.bundle/bin:node_modules/.bin:/usr/local/bin:/usr/local/sbin:$PATH

  brew install imagemagick --with-openexr --with-webp
  brew install openssl git hub aspell jq editorconfig ctags node libevent libsass python
  brew tap homebrew/versions
  brew install homebrew/versions/v8-315
  brew cask install iterm2 xquartz launchrocket gitx

  echo "\n# Use github's utility in place of git"
  echo 'alias git=hub' >> ~/.bash_profile
  echo
else
  echo Update brew...
  brew update

  if ! hash jq 2>/dev/null; then
    brew install jq
  fi

  if ! hash hub 2>/dev/null; then
    brew install hub
    echo "\n# Use github's utility in place of git" >> ~/.bash_profile
    echo 'alias git=hub' >> ~/.bash_profile
  fi
fi

if ! hash setup-vox-middleman 2>/dev/null; then
  echo "#!/bin/bash" >/usr/local/bin/setup-vox-middleman
  echo 'exec bash -c "$(curl -fsSL https://gist.github.com/ryanmark/9ec33d5d4ee572f7853e/raw/setup-vox-middleman.sh)"' >>/usr/local/bin/setup-vox-middleman
  chmod +x /usr/local/bin/setup-vox-middleman
fi

# make sure we have rbenv, and not rvm
if hash rvm 2>/dev/null; then
  echo ''
  echo 'DANGER!!! DANGER!!!'
  echo 'Please uninstall rvm in order to continue'
  echo ''
  exit 1
fi

if ! hash rbenv 2>/dev/null; then
  echo
  echo Installing rbenv...
  brew install rbenv
  echo
fi

if [ ! -d ~/.rbenv ]; then
  echo
  echo Initialize rbenv...
  rbenv init
  echo "\n# Load rbenv stuff" >> ~/.bash_profile
  echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
  echo
fi

if which ruby = '/usr/bin/ruby'; then
  eval "$(rbenv init -)"
fi

# make sure we don't have a .ruby-version in our home
if [ -f ~/.ruby-version ]; then
  echo
  echo Found .ruby-version in your home dir, removing it...
  rm ~/.ruby-version
fi

# make sure we have the correct ruby installed
if ! rbenv versions|grep $FAVORITE_RUBY >/dev/null; then
  echo Update ruby-build
  brew update
  brew upgrade ruby-build

  echo "Installing our favorite Ruby ($FAVORITE_RUBY)..."
  rbenv install $FAVORITE_RUBY

  echo Making sure we have bundler...
  rbenv shell $FAVORITE_RUBY
  gem install bundler
fi

if ! ruby --version|grep "2\.[234]\." >/dev/null; then
  echo "Default ruby needs to be >2.2, setting it to $FAVORITE_RUBY"
  rbenv global $FAVORITE_RUBY
fi

if ! hash bundle 2>/dev/null; then
  gem install bundler
fi

# make sure bundler is configured properly
echo Configuring bundler...
bundle config path '.bundle'
bundle config build.openssl "--with-cppflags=-I/usr/local/opt/openssl/include --with-ldflags=-L/usr/local/opt/openssl/lib"
bundle config build.eventmachine "--with-cppflags=-I/usr/local/opt/openssl/include --with-ldflags=-L/usr/local/opt/openssl/lib"
bundle config build.libv8 "--with-system-v8"
bundle config build.therubyracer "--with-cppflags=-I/usr/local/opt/v8-315/include --with-ldflags=-L/usr/local/opt/v8-315/lib"
bundle config build.puma "--with-cppflags=-I/usr/local/opt/openssl/include --with-ldflags=-L/usr/local/opt/openssl/lib"

# make sure rbenv permissions are sorted
echo 'Fixing permissions...'
sudo chown -R $USER $HOME/.rbenv
sudo chown -R $USER /usr/local

if [ ! -f ~/.ssh/id_rsa ]; then
  echo
  echo Missing ssh private key ~/.ssh/id_rsa. Please setup github access for
  echo both HTTPS and SSH. Instructions here:
  echo   https://help.github.com/articles/set-up-git/#setting-up-git
  exit 1
fi

if ! grep 'github.com' ~/.ssh/known_hosts; then
  ssh-keyscan github.com >> ~/.ssh/known_hosts
fi

# install middleman
echo 'Installing necessary gems...'
# download api client gem
cd /tmp
git clone git@github.com:voxmedia/chorus_api_client-ruby.git
cd chorus_api_client-ruby
gem build *gemspec

if [ "$(rbenv global)" == "system" ]; then
  sudo gem install middleman-google_drive octokit
  # install api client gem
  sudo gem install *gem
else
  gem install middleman-google_drive octokit
  # install api client gem
  gem install *gem
fi

# cleanup
cd ~
rm -Rf /tmp/chorus_api_client-ruby

echo
echo

# setup client secrets
if [ ! -f "~/.google_client_secrets.json" ]; then
    echo 'Installing Google client_secrets.json...'
    cd /tmp
    git clone git@github.com:voxmedia/vox-google-drive.git
    cp vox-google-drive/lib/client_secrets.json ~/.google_client_secrets.json
    cd ~
    rm -Rf /tmp/vox-google-drive
fi

echo
echo

# setup .middleman if doesn't exist
if [ ! -d ~/.middleman ]; then
    mkdir ~/.middleman
fi

if [ -d ~/.middleman/voxmedia ]; then
    echo 'Updating Vox Media Middleman template...'
    # update this repo in .middleman if exists
    cd ~/.middleman/voxmedia
    git checkout . >/dev/null
    git checkout master >/dev/null
    git pull origin master >/dev/null
else
    echo 'Installing Vox Media Middleman template...'
    # clone this repo into .middleman if doesn't exist
    cd ~/.middleman
    git clone git@github.com:voxmedia/voxmedia-middleman-template.git voxmedia
fi

echo
echo

# add api client id envvar
if [[ ! $CHORUS_API_CLIENT_ID -eq '24' ]]; then
  export CHORUS_API_CLIENT_ID=24
  echo 'export CHORUS_API_CLIENT_ID=24' >> ~/.bash_profile
  if [[ "$(basename $SHELL)" != 'bash' ]]; then
    echo 'Please add this to your shell profile config'
    echo '    export CHORUS_API_CLIENT_ID=24'
  fi
fi

# display instructions
echo 'You must start a new terminal session for changes to take affect.'
echo ''
echo 'You should be all set. To start a new editorial app, enter the following'
echo 'and follow the instructions.'
echo '    middleman init -T voxmedia my-new-app'
echo
echo 'Run setup-vox-middleman again at any time to update your install.'

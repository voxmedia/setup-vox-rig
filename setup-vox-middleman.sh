#!/bin/bash
#
# To run this script, enter this into your terminal:
# bash -c "$(curl -fsSL https://gist.github.com/ryanmark/9ec33d5d4ee572f7853e/raw/setup-vox-middleman.sh)"
FAVORITE_RUBY=2.2.2

echo 'Setting up Vox Media Middleman rig.'
echo ''

trap "exit 1" SIGINT;

# make sure we have rbenv, and not rvm
if hash rvm 2>/dev/null; then
  echo ''
  echo 'DANGER!!! DANGER!!!'
  echo 'Please uninstall rvm in order to continue'
  echo ''
  exit 1
fi

if ! hash rbenv 2>/dev/null; then
  echo ''
  echo 'DANGER!!! DANGER!!!'
  echo 'Please install rbenv in order to continue'
  echo ''
  exit 1
fi

# make sure we have the correct ruby installed
if ! rbenv versions|grep $FAVORITE_RUBY >/dev/null; then
  echo 'Update ruby-build'
  brew update
  brew upgrade ruby-build

  echo 'Installing our favorite Ruby...'
  rbenv install $FAVORITE_RUBY

  echo 'Making sure we have bundler...'
  rbenv shell $FAVORITE_RUBY
  gem install bundler
fi

# make sure we don't have a .ruby-version in our home
if [ -f ~/.ruby-version ]; then
  echo 'Removing .ruby-version from your home dir.'
  rm ~/.ruby-version
fi

if ! ruby --version|grep "2\.[234]\." >/dev/null; then
  echo "Default ruby needs to be >2.2, setting it to $FAVORITE_RUBY"
  rbenv global $FAVORITE_RUBY
fi

# make sure bundler is configured properly
if [ ! -f ~/.bundle/config ]; then
  echo 'Missing bundler config, fixing now...'
  mkdir -p ~/.bundle
  echo "---
BUNDLE_PATH: .bundle" > ~/.bundle/config
fi

# make sure rbenv permissions are sorted
echo 'Fixing permissions...'
sudo chown -R $USER $HOME/.rbenv

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

echo ''
echo ''

# setup client secrets
if [ ! -f "~/.google_client_secrets.json" ]; then
    echo 'Installing Google client_secrets.json...'
    cd /tmp
    git clone git@github.com:voxmedia/vox-google-drive.git
    cp vox-google-drive/lib/client_secrets.json ~/.google_client_secrets.json
    cd ~
    rm -Rf /tmp/vox-google-drive
fi

echo ''
echo ''

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

echo ''
echo ''

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
echo ''
echo 'Run this script again at any time to update your install.'

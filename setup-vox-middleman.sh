#!/bin/bash
#
# To run this script, enter this into your terminal:
# bash -c "$(curl -fsSL https://gist.github.com/ryanmark/9ec33d5d4ee572f7853e/raw/setup-vox-middleman.sh)"


echo 'Setting up Vox Media Middleman rig.'
echo ''

# install middleman
echo 'Installing necessary gems...'
sudo gem install middleman-google_drive
# download api client gem
cd /tmp
git clone git@github.com:voxmedia/chorus_api_client-ruby.git
cd chorus_api_client-ruby
gem build *gemspec
# install api client gem
sudo gem install *gem
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
    echo 'Please add this to your .bash_profile or whatever you use...'
    echo '    export CHORUS_API_CLIENT_ID=24'
    echo ''
fi

# display instructions
echo 'You should be all set. To start a new editorial app, enter the following'
echo 'and follow the instructions.'
echo '    middleman init -t voxmedia my-new-app'
echo ''
echo 'Run this script again at any time to update your install.'

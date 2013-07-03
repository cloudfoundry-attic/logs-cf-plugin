# Tail-Cf-Plugin [![Build Status](https://travis-ci.org/cloudfoundry/tail-cf-plugin.png?branch=master)](https://travis-ci.org/cloudfoundry/tail-cf-plugin)

Plugin to cf command to add streaming application logs.

## Installation

Add this line to your application's Gemfile:

    gem 'tail-cf-plugin'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tail-cf-plugin

## Usage

After installing you can run cf tail and see your application's logs stream to the console.

## Contributing

The Cloud Foundry team uses GitHub and accepts contributions via [pull request](https://help.github.com/articles/using-pull-requests)

Follow these steps to make a contribution to any of our open source repositories:

1. Complete our CLA Agreement for [individuals](http://www.cloudfoundry.org/individualcontribution.pdf) or [corporations](http://www.cloudfoundry.org/corpcontribution.pdf)
1. Set your name and email

    git config --global user.name "Firstname Lastname"
    git config --global user.email "your_email@youremail.com"

1. Fork the repo
1. Make your changes on a topic branch, commit, and push to github and open a pull request.

Once your commits are approved by Travis CI and reviewed by the core team, they will be merged.

#### Checkout

    git clone git@github.com:cloudfoundry/tail-cf-plugin.git
    cd tail-cf-plugin/
    bundle

#### Running tests

    rake


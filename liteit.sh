#/bin/env sh

firetower stop
cat ~/.firetower/firetower.conf.orig > ~/.firetower/firetower.conf
cat firebot.rb >> ~/.firetower/firetower.conf
firetower start

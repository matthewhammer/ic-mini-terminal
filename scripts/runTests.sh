#!/bin/bash
echo dfx start &&\
dfx start --background &&\
\
echo canister create &&\
dfx canister create textEdit &&\
\
echo build textEdit &&\
dfx build textEdit &&\
\
echo canister install &&\
dfx canister install textEdit &&\
\
echo canister call textEdit view  &&\
dfx canister call --output raw textEdit view '(record {width=100; height=100;}, vec { })' &&\
\
echo canister call textEdit update &&\
dfx canister call --output raw textEdit update 'vec { }' &&\
\
echo canister call textEdit view  &&\
dfx canister call --output raw textEdit view '(record {width=100; height=100;}, vec { })' &&\
\
echo dfx stop &&\
dfx stop &&\
\
echo Tests done. Success.


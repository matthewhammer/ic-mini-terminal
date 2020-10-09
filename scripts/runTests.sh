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
echo canister call windowSizeChange &&\
dfx canister call windowSizeChange 'record {width=100; height=100; }' &&\
\
echo canister call queryKeyDown &&\
dfx canister call queryKeyDown 'vec { }' &&\
\
echo Tests done. Success.


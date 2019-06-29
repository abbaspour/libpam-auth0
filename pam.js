#!/usr/bin/env node
'use strict';

const fs = require('fs');
const readline = require('readline');
const https = require("https");

const PAM_SUCCESS = 0;
const PAM_SERVICE_ERR = 3;
const PAM_SYSTEM_ERR = 4;
const PAM_AUTH_ERR = 7;
const PAM_AUTHINFO_UNAVAIL = 9;
const PAM_NO_MODULE_DATA = 18;

const DEFAULT_CONFIG_FILE = '/etc/auth0.conf';

function error(msg, code) {
    console.log(new Date().toISOString() + ' ERROR: ' + msg);
    process.exit(code);
}

function debug(msg) {
    console.log(new Date().toISOString() + ' DEBUG: ' + msg);
}

function getUser() {
    let pam_type = process.env.PAM_TYPE;
    let pam_user = process.env.PAM_USER;

    if (!pam_type || pam_type !== 'auth') error('PAM type not supported: ' + pam_type, PAM_SYSTEM_ERR);
    if (!pam_user) error('undefined PAM_USER', PAM_SYSTEM_ERR);

    return pam_user;
}

function getConfig() {
    let config_file = process.env.CONFIG_FILE || DEFAULT_CONFIG_FILE;
    let valid_line = /^[^#]\S+=\S+/;

    debug('reading config file: ' + config_file);

    try {
        let data = fs.readFileSync(config_file, 'ascii');
        let config = {};
        data.split('\n').filter(s => s.match(valid_line)).map(s => s.split('=')).map(p => config[p[0]] = p[1]);
        return config;
    } catch (e) {
        error('reading config file: ' + config_file, PAM_NO_MODULE_DATA);
    }
}

function readPassword() {
    let rl = readline.createInterface({input: process.stdin, terminal: false, prompt: '', output: null});
    return new Promise(resolve => rl.question('', l => resolve(l)));
}

function authenticate(config, username, password) {

    let body = {
        grant_type: 'password', client_id: config.AUTH0_CLIENT_ID, username: username, password: password, scope: 'none'
    };

    if (config.AUTH0_CONNECTION) {
        body.grant_type = 'http://auth0.com/oauth/grant-type/password-realm';
        body.realm = config.AUTH0_CONNECTION;
    }

    if (config.AUTH0_CLIENT_SECRET) body.client_secret = config.AUTH0_CLIENT_SECRET;

    let postData = JSON.stringify(body);

    let options = {
        hostname: config.AUTH0_DOMAIN, port: 443, path: '/oauth/token', method: 'POST',
        headers: {'Content-Type': 'application/json', 'Content-Length': postData.length}
    };

    return new Promise(resolve => {
        let req = https.request(options, res => {
            debug('auth request status code for user ' + username + ': ' + res.statusCode);
            resolve(res.statusCode === 200 ? PAM_SUCCESS : PAM_AUTH_ERR);
        });

        req.on('error', e => error('error on https request: ' + e.message, PAM_AUTHINFO_UNAVAIL));
        req.write(postData);
        req.end();
    });
}

function main() {
    let username = getUser();
    debug('authenticating user: ' + username);

    let config = getConfig();

    readPassword()
        .then(pwd => authenticate(config, username, pwd))
        .then(code => process.exit(code))
        .catch(e => error('error: ' + e.message, PAM_SERVICE_ERR));
}

main();


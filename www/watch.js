/*
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
*/

var argscheck = require('cordova/argscheck'),
    channel = require('cordova/channel'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec'),
    cordova = require('cordova');

function Watch() {};

/**
 * Init
 *
 * @param {Function} successCallback The function to call when the heading data is available
 * @param {Function} errorCallback The function to call when there is an error getting the heading data. (OPTIONAL)
 */
// Watch.prototype.init = function(successCallback, errorCallback) {
//     argscheck.checkArgs('fF', 'Watch.init', arguments);
//     exec(successCallback, errorCallback, "Watch", "init", []);
// };

Watch.prototype.registerForWatchEvents = function(successCallback, errorCallback) {
    argscheck.checkArgs('fF', 'Watch.registerForWatchEvents', arguments);
    exec(successCallback, errorCallback, "Watch", "registerForWatchEvents", []);
};

Watch.prototype.sendMessage = function(message, successCallback, errorCallback) {
    argscheck.checkArgs('ofF', 'Watch.sendMessage', arguments);
    exec(successCallback, errorCallback, "Watch", "sendMessage", [message]);
};

Watch.prototype.transferUserInfo = function(info, successCallback, errorCallback) {
    argscheck.checkArgs('ofF', 'Watch.transferUserInfo', arguments);
    exec(successCallback, errorCallback, "Watch", "transferUserInfo", [info]);
};

Watch.prototype.updateApplicationContext = function(context, successCallback, errorCallback) {
    argscheck.checkArgs('ofF', 'Watch.updateApplicationContext', arguments);
    exec(successCallback, errorCallback, "Watch", "updateApplicationContext", [context]);
};

Watch.prototype.getLatestApplicationContext = function(successCallback, errorCallback) {
    argscheck.checkArgs('fF', 'Watch.getLatestApplicationContext', arguments);
    exec(successCallback, errorCallback, "Watch", "getLatestApplicationContext", []);
};

module.exports = new Watch();

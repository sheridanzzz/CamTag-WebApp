/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: The location service provides a wrapper for the HTML location functionality.
*/

import { Injectable } from '@angular/core';

@Injectable()
export class LocationService {
    _navigator = <any>navigator;
    constructor() { }

    getLocation() {
        return new Promise((resolve, reject) => {
            if (this._navigator.geolocation) {
                navigator.geolocation.getCurrentPosition((position) => {
                    resolve(position);
                }, (error) => {
                    reject(error);
                });
            } else {
                alert("Geolocation is not supported by this browser.");
                reject("sad");
            }
        });
    }
}
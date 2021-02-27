/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: The storage service provides a wrapper for HTML localStorage, and also provides a simple memory storage function using an object.
*/

import { Injectable } from '@angular/core';

@Injectable()
export class StorageService {
    constructor() { }
    private memoryStorage = {};

    setItem(key: string, item: any): void {
        localStorage.setItem(key, item);
    }

    getItem(key: string): any {
        return localStorage.getItem(key);
    }

    removeItem(key: string): any {
        return localStorage.removeItem(key);
    }

    setMemoryStorage(key: string, item: any): void {
        this.memoryStorage[key] = item;
    }

    getMemoryStorage(key: string): any {
        return this.memoryStorage[key];
    }

    removeMemoryStorage(key: string): any {
        delete this.memoryStorage[key];
    }

    clearEverything() {
        this.memoryStorage = {};
        localStorage.clear();
    }
}
/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.
*/

import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { StorageService } from 'src/app/core/storage.service';


@Component({
    selector: 'settings-page',
    templateUrl: './settings.component.html',
    styleUrls: ['./settings.component.css']
})
export class SettingsComponent implements OnInit {
    @Input() settings: any;
    @Output() applySettings: EventEmitter<any> = new EventEmitter<any>();
    @Output() goBack: EventEmitter<any> = new EventEmitter<any>();
    timeLimitMins = 180;
    startDelayMins = 1;
    replenishAmmoDelayMins = 2;
    showMapModal = false;

    constructor(private storage: StorageService) { }

    ngOnInit() {
        console.log("SETTINGS from settings page:", this.settings);
    }

    backButton() {
        this.goBack.emit();
    }

    setBRMap() {
        const coordinates = this.storage.getMemoryStorage('BRMapCoords');
        this.settings.latitude = coordinates.lat;
        this.settings.longitude = coordinates.long;
        this.settings.radius = coordinates.radius;
        console.log(coordinates);
        this.apply();
    }

    apply() {
        if (this.settings.gameMode == "BR" && this.showMapModal == false) {
            this.showMapModal = true;
        } else {
            this.settings.timeLimit = this.timeLimitMins * 60000;
            this.settings.startDelay = this.startDelayMins * 60000;
            this.settings.replenishAmmoDelay = this.replenishAmmoDelayMins * 60000;
            this.applySettings.emit(this.settings);
        }
    }
}
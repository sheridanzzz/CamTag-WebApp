/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: The Create component is responsible for setting up a new game. It uses the selfie, settings and verification
components to do so.
*/

import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Location } from '@angular/common';

import { StorageService } from '../../core/storage.service';
import { ApiService } from '../../core/api.service';
import { PushService } from '../../core/push.service';
import { finalize } from 'rxjs/operators';
import { MessageService } from 'src/app/core/message.service';

@Component({
    selector: 'create-page',
    templateUrl: './create.component.html',
    styleUrls: ['./create.component.css']
})

export class CreateComponent implements OnInit {
    view = 0;
    valid = {
        playerName: false,
        contactID: false
    }

    gameDetails = {
        nickname: '',
        contact: '',
        imgUrl: '',
        timeLimit: 600000,
        ammoLimit: 3,
        startDelay: 10000,
        replenishAmmoDelay: 600000,
        gameMode: 'CORE',
        isJoinableAtAnyTime: true,
        latitude: 0,
        longitude: 0,
        radius: 0
    }

    creating = false;
    created = false;
    playerID = '';
    verificationCode = '';

    constructor(private router: Router, private storage: StorageService, private api: ApiService, private pushService: PushService, private location: Location, private messageService: MessageService) { }

    ngOnInit() {
        if (this.storage.getItem("VerifyingCreatePlayerID") != null) {
            this.playerID = this.storage.getItem("VerifyingCreatePlayerID");
            this.view = 4;
        } else {
            if (this.storage.getItem("VerifyingJoinPlayerID") != null) {
                if (confirm("You are currently joining a game. Are you sure you want to leave that and create a game instead?")) {
                    this.api.unverifiedLeaveGame(this.storage.getItem("VerifyingJoinPlayerID")).subscribe(res => {
                        this.storage.removeItem("VerifyingJoinPlayerID");
                        this.view = 1;
                    }, (err) => {
                        this.storage.removeItem("VerifyingJoinPlayerID");
                        this.view = 1;
                    });
                } else {
                    this.router.navigateByUrl("/start");
                }
            } else {
                this.view = 1;
            }
        }
    }

    acceptSelfie() {
        this.view = 2;
    }

    showHelp() {
        this.messageService.showHelp();
    }

    applySettings() {
        this.view = 3;
    }

    // Calls the API to actually create the game, and sends the player to the verification screen once this has occurred.
    createGame() {
        if (this.valid.playerName && this.valid.contactID) {
            this.creating = true;
            console.log("Game Details:", this.gameDetails);
            this.api.createGame(this.gameDetails)
                .pipe(finalize(() => {
                    this.creating = false;
                }))
                .subscribe(res => {
                    this.playerID = res.data.playerID;
                    this.storage.setItem("VerifyingCreatePlayerID", res.data.playerID);
                    this.created = true;
                    this.view = 4;
                }, err => {
                    this.messageService.pushMessage('Warning', err.errorMessage);
                });
        } else {
            this.messageService.pushMessage('Invalid Inputs', 'Please confirm you have entered a valid email address and nickname.');
        }
    }

    // Validates that the contact input matches a mobile phone number or email address.
    validateContact() {
        const phoneRegex = new RegExp(/^0[0-8]\d{8}$/g);
        const emailRegex = new RegExp(/.+@.+\..+/i);

        if (phoneRegex.test(this.gameDetails.contact)) {
            this.valid.contactID = true;
        } else if (emailRegex.test(this.gameDetails.contact)) {
            this.valid.contactID = true;
        } else {
            this.valid.contactID = false;
        }
    }

    // Confirm that the player was verified from the verification component.
    checkVerification(isVerified) {
        if (isVerified) {
            this.storage.setItem('PlayerID', this.playerID);
            this.storage.setItem('PlayerIsHost', true);
            this.pushService.initialise();
        } else {
            this.view == 3;
        }
    }

    // If the player leaves the verification page without verifying themselves, they need to be removed from the game.
    unverified() {
        console.log("Unverified");
        this.storage.removeItem("VerifyingCreatePlayerID");
        console.log(this.gameDetails);
        if (this.gameDetails.imgUrl == '') {
            this.view = 1;
        } else {
            this.view = 3;
        }
    }
}
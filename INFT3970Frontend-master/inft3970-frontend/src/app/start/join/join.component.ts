/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: The Join component is responsible for handling players joining a game. It also uses the selfie and verification components.
*/

import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Location } from '@angular/common';

import { StorageService } from '../../core/storage.service';
import { ApiService } from '../../core/api.service';
import { PushService } from '../../core/push.service';
import { MessageService } from 'src/app/core/message.service';

@Component({
    selector: 'join-page',
    templateUrl: './join.component.html',
    styleUrls: ['./join.component.css']
})
export class JoinComponent implements OnInit {
    view = 0;
    roomCode = '';
    playerName = '';
    contactID = '';
    playerImgUrl = '';
    valid = {
        roomCode: false,
        playerName: false,
        contactID: false
    }

    joining = false;
    joined = false;
    playerID = '';
    verificationCode = '';

    constructor(private router: Router, private storage: StorageService, private api: ApiService, private pushService: PushService, private location: Location, private messageService: MessageService) { }

    ngOnInit() {
        if (this.storage.getItem("VerifyingJoinPlayerID") != null) {
            this.playerID = this.storage.getItem("VerifyingJoinPlayerID");
            this.view = 3;
        } else {
            if (this.storage.getItem("VerifyingCreatePlayerID") != null) {
                if (confirm("You are currently creating a game. Are you sure you want to leave that and join a game instead?")) {
                    this.api.unverifiedLeaveGame(this.storage.getItem("VerifyingCreatePlayerID")).subscribe(res => {
                        this.storage.removeItem("VerifyingCreatePlayerID");
                        this.view = 1;
                    }, (err) => {
                        this.storage.removeItem("VerifyingCreatePlayerID");
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

    // Makes the actual API request to the server, and displays the verification component for the player if successful.
    joinGame() {
        if (this.valid.roomCode && this.valid.playerName && this.validateContact) {
            this.joining = true;
            this.api.joinGame(this.roomCode, this.playerName, this.contactID, this.playerImgUrl).subscribe(res => {
                this.joined = true;
                this.playerID = res.data.playerID;
                this.storage.setItem("VerifyingJoinPlayerID", res.data.playerID);
                this.view = 3;
            }, err => {
                console.log('Error:', err);
                this.messageService.pushMessage('Warning', err.errorMessage);
            }, () => {
                console.log('Finished a subscription call');
                this.joining = false;
            });
        } else {
            this.messageService.pushMessage('Invalid Inputs', 'Please confirm you have entered a valid email address, nickname and room code.');
        }
    }

    // Ensures that the contact details are a valid mobile phone number or email address.
    validateContact() {
        const phoneRegex = new RegExp(/^0[0-8]\d{8}$/g);
        const emailRegex = new RegExp(/.+@.+\..+/i);

        if (phoneRegex.test(this.contactID)) {
            this.valid.contactID = true;
        } else if (emailRegex.test(this.contactID)) {
            this.valid.contactID = true;
        } else {
            this.valid.contactID = false;
        }
    }

    // Confirms that the player has been verified, and triggers the push service initialisation
    checkVerification(isVerified) {
        if (isVerified) {
            this.storage.setItem('PlayerID', this.playerID);
            this.storage.setItem('PlayerIsHost', false);
            this.pushService.initialise();
        } else {
            this.view == 2;
            this.messageService.pushMessage("Verification", "There seems to be an issue with verifying the inputs are correct.");
        }

    }

    // Removes the player from the game if they decide not to verify themselves.
    unverified() {
        this.storage.removeItem("VerifyingJoinPlayerID");
        if (this.playerImgUrl == '') {
            this.view = 1;
        } else {
            this.view = 2;
        }
    }
}
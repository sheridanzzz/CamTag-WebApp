/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: The Verification component allows a user to enter a verification code to confirm that their contact details are valid.
*/

import { Component, Input, Output, EventEmitter, OnInit } from '@angular/core';
import { finalize } from 'rxjs/operators';
import { ApiService } from '../../core/api.service';
import { MessageService } from 'src/app/core/message.service';
import { PushService } from 'src/app/core/push.service';

@Component({
    selector: 'verification-page',
    templateUrl: './verification.component.html',
    styleUrls: ['./verification.component.css']
})

export class VerificationComponent implements OnInit {
    @Input() playerID: string;
    @Output() verified: EventEmitter<boolean> = new EventEmitter<boolean>();
    @Output() goBack: EventEmitter<any> = new EventEmitter<any>();
    verificationCode = '';
    verifiedFlag = false;

    constructor(private api: ApiService, private messageService: MessageService, private pushService: PushService) { }

    ngOnInit() {}

    back() {
        this.api.unverifiedLeaveGame(this.playerID).subscribe(res => {
            this.pushService.disconnect();
            this.goBack.emit();
        }, (err) => {
            console.log('Error removing player:', err);
            this.pushService.disconnect();
            this.goBack.emit();
        });
    }

    // Sends the entered code to the server with the player ID to confirm.
    verifyContact() {
        console.log(this.playerID, this.verificationCode);
        this.api.verifyPlayer(this.playerID, this.verificationCode)
            .pipe(finalize(() => {
                this.verified.emit(this.verifiedFlag);
            }))
            .subscribe(res => {
                this.verifiedFlag = true;
            }, err => {
                this.messageService.pushMessage('Error Verifying', err.errorMessage);
            });
    }

    // Requests the server to resend a new verification code.
    resendCode() {
        console.log(this.playerID, this.verificationCode);
        this.api.resendVerificationCode(this.playerID)
            .pipe(finalize(() => {

            }))
            .subscribe(res => {
                console.log('resent code');
                this.messageService.pushMessage("Success", "Code was resent. Please give it a moment.");
            });
    }
}
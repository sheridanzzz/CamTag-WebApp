/*
This component was written for the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: This component displays the message page when something needs to be shown to the user. If multiple messages are pushed, they will all come through the one view.
*/

import { Component, OnInit, EventEmitter, Output } from '@angular/core';
import { MessageService } from '../message.service';

@Component({
    selector: 'message-page',
    templateUrl: './message.component.html',
    styleUrls: ['./message.component.css']
})

export class MessageComponent implements OnInit {
    @Output() close: EventEmitter<any> = new EventEmitter<any>();
    messages = [];
    messageTitle = '';
    message = '';
    
    constructor(private messageService: MessageService) { }

    ngOnInit() {
        this.messages = this.messageService.messages;
        if (this.messages.length > 0) {
            this.messageTitle = this.messages[0].messageTitle;
            this.message = this.messages[0].message;
        }
    }

    acceptMessage() {
        this.messages.shift();
        if (this.messages.length > 0) {
            this.messageTitle = this.messages[0].messageTitle;
            this.message = this.messages[0].message;
        } else {
            this.close.emit();
        }
    }
}
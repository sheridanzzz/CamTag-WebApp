/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: The message service is a global service that any component can use to show a message. When the pushMessage function is triggered,
it will either cause the message modal to display, or if it is already displaying will add the message to a list of messages that will be displayed.
*/

import { Injectable } from '@angular/core';
import { Subject } from 'rxjs';

@Injectable()
export class MessageService {
    public messages = [];
    public showMessageModal = new Subject();
    public showHelpModal = new Subject();
    constructor() { }

    pushMessage(messageTitle, message) {
        this.messages.push({ messageTitle: messageTitle, message: message });
        this.showMessageModal.next();
    }

    showHelp() {
        this.showHelpModal.next();
    }
}
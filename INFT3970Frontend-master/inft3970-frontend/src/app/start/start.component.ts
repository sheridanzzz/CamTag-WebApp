/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: Provides a basic start page where the user can decide whether to then create or join a game.
*/

import { Component } from '@angular/core';
import { MessageService } from '../core/message.service';

@Component({
    selector: 'start-page',
    templateUrl: './start.component.html',
    styleUrls: ['./start.component.css']
})
export class StartComponent {
    constructor(private messageService: MessageService) { }

    showHelp() {
        this.messageService.showHelp();
    }
}
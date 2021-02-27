/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: The Scoreboard component provides an up-to-date list of the players in the game and what their scores are. 
Also displays players who have left the game. This is also the main page once the game has ended.
*/

import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';

import { ApiService } from '../../core/api.service';
import { PushService } from '../../core/push.service';
import { MessageService } from 'src/app/core/message.service';
import { Router } from '@angular/router';
import { StorageService } from 'src/app/core/storage.service';

@Component({
    selector: 'scoreboard-page',
    templateUrl: './scoreboard.component.html',
    styleUrls: ['./scoreboard.component.css']
})
export class ScoreboardComponent implements OnInit, OnDestroy {
    players: any;
    gameType = '';
    gameState = '';
    roomCode = '';
    endTime = '';
    loading = false;
    private scoreboardSub;
    private gameCompletedSub;

    constructor(private api: ApiService, private pushService: PushService, private ref: ChangeDetectorRef, private messageService: MessageService, private router: Router, private storage: StorageService) { }

    showHelp() {
        this.messageService.showHelp();
    }

    goBack() {
        this.router.navigateByUrl('/');
    }

    leaveGame() {
        if (confirm("Are you sure you want to leave this game?")) {
            this.pushService.disconnect();
            this.storage.clearEverything();
            this.router.navigateByUrl('/start');
        }
    }

    ngOnInit() {
        this.gameState = this.storage.getItem('GameState');
        this.scoreboardSub = this.pushService.scoreboardPlayerList.subscribe((res) => {
            this.loadScoreboard();
        });

        this.gameCompletedSub = this.pushService.gameCompleted.subscribe((res) => {
            this.gameState = 'COMPLETED';
            this.loadScoreboard();
        });
    }

    ngOnDestroy() {
        this.scoreboardSub.unsubscribe();
        this.gameCompletedSub.unsubscribe();
    }

    // Loads the data from the server to display on the scoreboard. Ordered by most kills.
    loadScoreboard() {
        this.loading = true;
        let requestType = 'Ingameall';
        if (this.gameState == 'COMPLETED') {
            requestType = 'All';
        }
        this.api.getListOfPlayers(true, requestType, 'KILLS').subscribe(res => {
            this.players = res.data.players;
            this.gameState = res.data.gameState;
            this.gameType = res.data.gameMode;
            this.roomCode = res.data.gameCode;
            this.endTime = res.data.endTime;
            console.log(this.players);
        }, error => {
            console.log('Error:', error);
        }, () => {
            this.loading = false;
            this.ref.detectChanges();
        });
    }
}
/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: Provides a page where the players wait for the game to start and while it is starting.
*/

import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { finalize } from 'rxjs/operators';
import { Router } from '@angular/router';

import { ApiService } from '../../core/api.service';
import { StorageService } from '../../core/storage.service';
import { PushService } from '../../core/push.service';
import { MessageService } from 'src/app/core/message.service';

@Component({
    selector: 'lobby-page',
    templateUrl: './lobby.component.html',
    styleUrls: ['./lobby.component.css']
})

export class LobbyComponent implements OnInit, OnDestroy {
    players: any;
    loading = false;
    gameCode = '';
    gameType = '';
    gameState = '';
    startTime = '';
    isHost = false;
    private lobbySubscription;
    private gameStartingSubscription;
    private gameNowPlayingSubscription;
    private lobbyEndedSubscription;

    constructor(private api: ApiService, private storage: StorageService, private pushService: PushService, private ref: ChangeDetectorRef, private router: Router, private messageService: MessageService) { }

    showHelp() {
        this.messageService.showHelp();
    }

    ngOnInit() {
        this.lobbySubscription = this.pushService.lobbyPlayerList.subscribe((res) => {
            console.log('Lobby was triggered to updated');
            this.loadLobby();
        });
        this.gameStartingSubscription = this.pushService.gameStarting.subscribe((res) => {
            if (!this.isHost) {
                this.messageService.pushMessage('Game Status Update', 'The game is starting soon.');
            }
            this.loadLobby();
        });
        this.gameNowPlayingSubscription = this.pushService.gameNowPlaying.subscribe((res) => {
            console.log('Received SignalR to start playing game');
            this.messageService.pushMessage("Game Start", "The game has now started.");
            this.storage.setItem("GameState", "PLAYING");
            this.storage.setItem("PlayerStatus", "ACTIVE");
            this.router.navigateByUrl('/');
            this.ref.detectChanges();
        });

        this.lobbyEndedSubscription = this.pushService.lobbyEnded.subscribe((res) => {
            console.log("The lobby has ended.");
            this.lobbyEnded();
        });

        this.isHost = this.storage.getItem('PlayerIsHost');
    }

    // Unsubscribes any Subscriptions when a player leaves the page.
    ngOnDestroy() {
        this.lobbySubscription.unsubscribe();
        this.gameStartingSubscription.unsubscribe();
        this.gameNowPlayingSubscription.unsubscribe();
        this.lobbyEndedSubscription.unsubscribe();
    }

    // If the lobby/game ends before the game starts, then clear out data and return to start page.
    lobbyEnded() {
        this.messageService.pushMessage('Lobby Ended', 'The host has ended this lobby.');
        this.storage.clearEverything();
        this.router.navigateByUrl('start');
    }

    // Requests all the lobby data from the server so that it can display current players in the lobby.
    loadLobby() {
        this.loading = true;
        let listType = 'Ingame';
        if (this.isHost) {
            listType = 'Host';
        }
        this.api.getListOfPlayers(true, listType, 'AZ')
            .pipe(finalize(() => {
                this.loading = false;
                this.ref.detectChanges();
            }))
            .subscribe(res => {
                if (res.data.gameState == "PLAYING") {
                    this.router.navigateByUrl("/");
                } else {
                    console.log(res.data);
                    this.players = res.data.players;
                    this.gameCode = res.data.gameCode;
                    this.gameType = res.data.gameMode;
                    this.gameState = res.data.gameState;
                    this.startTime = res.data.startTime;
                    const devicePlayerID = this.storage.getItem('PlayerID');

                    const index = this.players.findIndex(el => el.playerID == devicePlayerID);
                    if (index >= 0) {
                        this.isHost = this.players[index].isHost;
                        console.log("Player Host:", this.isHost);
                    }
                }
            }, error => {
                console.log('ERROR CALLBACK');
            });
    }

    // Triggers the game to start. Only works if the person triggering is the host.
    beginGame() {
        this.loading = true;
        this.api.beginGame()
            .pipe(finalize(() => {
                this.loading = false;
                this.ref.detectChanges();
            }))
            .subscribe(res => {
                this.gameState = res.data.gameState;
                this.startTime = res.data.startTime;
            }, err => {
                this.messageService.pushMessage('Cannot Start Game', err.errorMessage);
            });
    }

    // Player can use this to leave the lobby before the game has started.
    leaveGame() {
        console.log('clicked leave game');
        if (confirm("Are you sure you want to leave the lobby?")) {
            this.api.postLeaveGame().subscribe(res => {
                this.pushService.disconnect();
                this.storage.clearEverything();
                this.router.navigateByUrl('start');
            }, err => {
                console.log('Error:', err);
            });
        }
    }

    // Host can remove an unverified player from the lobby.
    removePlayer(playerID) {
        console.log("Clicked button to remove player");
        if (confirm("Are you sure you want to remove this player from the lobby?"))
            this.api.removeUnverifiedPlayer(playerID).subscribe(res => {
                console.log('Removed player');
                this.loadLobby();
            });
    }
}
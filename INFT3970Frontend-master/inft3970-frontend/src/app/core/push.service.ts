/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: The Push Service handles the bi-directional web socket connection between the client app and the server. It is responsible
for starting and maintaining the connection, and sending out appropriate responses when the server calls a client function.
*/

import { Injectable } from '@angular/core';
import { HubConnection, HubConnectionBuilder, LogLevel } from '@aspnet/signalr';
import { Subject, BehaviorSubject } from "rxjs";
import { Router } from '@angular/router';

import { ApiService } from './api.service';
import { environment } from '../../environments/environment';
import { StorageService } from './storage.service';
import { AuthGuard } from './auth-guard.service';
import { ErrorService } from './error.service';

@Injectable()
export class PushService {
    private connection: HubConnection;
    private conPoll = null;
    private isConnected = false;

    public isConnectedTest = new Subject();
    public lobbyPlayerList = new BehaviorSubject(null);
    public scoreboardPlayerList = new BehaviorSubject(null);
    public notificationUpdate = new BehaviorSubject(0);
    public lobbyEnded = new Subject();
    public photoVoteUpdate = new Subject();
    public gameCompleted = new Subject();
    public ammoReplenished = new Subject();
    public gameNowPlaying = new Subject();
    public gameStarting = new Subject();
    public playerDisabled = new Subject();
    public playerReenabled = new Subject();
    public playerEliminated = new Subject();

    constructor(private api: ApiService, private storage: StorageService, private router: Router, private authGuard: AuthGuard, private errorService: ErrorService) { }

    // Initialise is responsible for building the connection object, and triggering the initial connection.
    initialise() {
        if (this.storage.getItem('PlayerID')) {
            try {
                let builder = new HubConnectionBuilder();
                this.connection = builder
                    .withUrl(environment.baseURL + "/app?playerID=" + this.storage.getItem('PlayerID'))
                    .configureLogging(LogLevel.Trace)
                    .build();
                this.setupObservables();
                this.connect();
            } catch (e) {
                console.log('Could not set up SignalR:', e);
            }
        }
    }

    // This function connects the Connection object to the backend server. It ensures that the connection should exist, and also
    // sets up a poll to maintain the connection if it drops for some reason (SignalR also handles this directly).
    connect() {
        if (!this.conPoll) {
            console.log('setting interval');
            this.conPoll = setInterval(() => {
                this.connect();
            }, 5000);
        }
        if (this.storage.getItem('PlayerID') && this.connection != null && !this.isConnected && document.visibilityState != 'hidden') {
            try {
                this.connection.start().then((con) => {
                    if (this.conPoll != null) {
                        clearInterval(this.conPoll);
                        this.conPoll = null;
                    }
                    this.isConnected = true;
                    this.isConnectedTest.next(1);
                    console.log("STATE of IsCOnnected:", this.isConnected);
                    this.updateData();
                }).catch(err => {
                    console.log('Error:', err);
                });
            } catch (e) {
                console.log('Error for SignalR:', e);
            }
        } else {
            console.log('Connection either cannot be created or already exists.');
        }
    }

    disconnect() {
        if (this.connection != null) {
            this.connection.stop();
        }
    }

    // The updateData method is called whenever the Connection is established. This ensures that any important SignalR triggers that may have been
    // missed while offline are covered so that the app is up-to-date with info again.
    // Examples include: Checking for any votes, ensuring that the player is valid, and checking what state the game is in.
    updateData() {
        this.api.getGameStatus()
            .subscribe(res => {
                if (!res.data.player || res.data.player.isDeleted || res.data.player.hasLeftGame || res.data.player.game.gameState == "NOGAME") { //If the player is no longer in the game
                    this.storage.clearEverything();
                    // this.disconnect();
                    this.router.navigateByUrl('/start');
                } else {
                    this.storage.setItem("GameState", res.data.player.game.gameState);
                    const gameState = res.data.player.game.gameState;
                    if (res.data.player.isEliminated) {
                        this.storage.setItem("PlayerStatus", "ELIMINATED");
                        this.router.navigateByUrl("/scoreboard");
                    }
                    if (res.data.player.isDisabled) {
                        this.storage.setItem("PlayerStatus", "DISABLED");
                        this.playerDisabled.next(1);
                    } else if (this.storage.getItem("PlayerStatus") == 'DISABLED') {
                        this.storage.setItem("PlayerStatus", "ACTIVE");
                        this.playerDisabled.next(0);
                    }

                    if (res.data.hasVotesToComplete) {
                        this.photoVoteUpdate.next();
                    }

                    switch (gameState) {
                        case 'IN LOBBY':
                        case 'STARTING':
                            if (this.authGuard.checkAuthorisedPage(this.router.url)) {
                                this.lobbyPlayerList.next(null);
                            }
                            break;
                        case 'PLAYING':
                            if (this.authGuard.checkAuthorisedPage(this.router.url)) {
                                if (res.data.hasNotifications) {
                                    this.notificationUpdate.next(0);
                                    this.ammoReplenished.next();
                                }
                            }
                            break;
                        case 'COMPLETED':
                            if (this.authGuard.checkAuthorisedPage(this.router.url)) {
                                this.scoreboardPlayerList.next(null);
                            }
                            break;
                    }
                }
            }, err => {
                this.errorService.throwError('Error Getting Game Status', err.errorMessage);
            });
    }

    // SetupObserbables subscribes the Connection object to the functions that the server may trigger, and assigns them to
    // Subjects in the app so that other components can subscribe locally and get active updates.
    setupObservables() {
        this.connection.on("UpdateGameLobbyList", (payload) => {
            console.log("PUSH RECEIVED: UpdateGameLobbyList");
            this.lobbyPlayerList.next(payload);
        });

        this.connection.on("LobbyEnded", (payload) => {
            console.log("PUSH RECEIVED: LobbyEnded");
            this.lobbyEnded.next(payload);
        });

        this.connection.on("UpdateScoreboard", (payload) => {
            console.log("PUSH RECEIVED: UpdateScoreboard");
            this.scoreboardPlayerList.next(payload);
        });

        this.connection.on("UpdateNotifications", (payload) => {
            console.log("PUSH RECEIVED: UpdateNotifications");
            this.notificationUpdate.next(payload);
        });

        this.connection.on("GameCompleted", (payload) => {
            console.log("PUSH RECEIVED: GameCompleted");
            this.gameCompleted.next(payload);
        });

        this.connection.on("UpdatePhotoUploaded", (payload) => {
            console.log("PUSH RECEIVED: UpdatePhotoUploaded");
            this.photoVoteUpdate.next(payload);
        });

        this.connection.on("AmmoReplenished", (payload) => {
            console.log("PUSH RECEIVED: AmmoReplenished");
            this.ammoReplenished.next(payload);
        });

        this.connection.on("GameStarting", (payload) => {
            console.log("PUSH RECEIVED: GameStarting");
            this.gameStarting.next(payload);
        });

        this.connection.on("GameNowPlaying", (payload) => {
            console.log("PUSH RECEIVED: GameNowPlaying");
            this.gameNowPlaying.next(payload);
        });

        this.connection.on("PlayerDisabled", (payload) => {
            console.log("PUSH RECEIVED: PlayerDisabled");
            this.playerDisabled.next(payload);
        });

        this.connection.on("PlayerReEnabled", (payload) => {
            console.log("PUSH RECEIVED: PlayerReEnabled");
            this.playerReenabled.next(payload);
        });

        this.connection.on("PlayerEliminated", (payload) => {
            console.log("PUSH RECEIVED: PlayerEliminated");
            this.playerEliminated.next(payload);
        });

        this.connection.onclose((error) => {
            this.isConnectedTest.next(0);
            this.isConnected = false;
            if (this.conPoll != null) {
                clearInterval(this.conPoll);
                this.conPoll = null;
            }
            console.log("Connection state:", this.isConnected);
        });
    }
}
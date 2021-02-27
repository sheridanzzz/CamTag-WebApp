/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: This service handles all API requests. It has two generic GET and POST functions, and custom functions for all the 
specific requirements which are then passed through the generic functions. 
*/

import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, Subject } from 'rxjs';
import { StorageService } from './storage.service';
import { Response } from './models/response';
import { Router } from '@angular/router';
import { ErrorService } from './error.service';
import { environment } from '../../environments/environment';

@Injectable()
export class ApiService {
    waitingForServer = new Subject();
    concurrentServerCallCounter = 0;

    constructor(private http: HttpClient, private storage: StorageService, private router: Router, private errorService: ErrorService) { }

    // These two counters are used to indicate when the app is still waiting for responses from the server.
    incrementServerCallCounter() {
        this.concurrentServerCallCounter++;
        this.waitingForServer.next(true);
    }

    decrementServerCallCounter() {
        this.concurrentServerCallCounter--;
        if (this.concurrentServerCallCounter <= 0) {
            this.waitingForServer.next(false);
        }
    }


    genericGet(url, options): Observable<Response> {
        this.incrementServerCallCounter();
        return new Observable((observer) => {
            this.http.get<Response>(environment.baseURL + url, options).subscribe((res: any) => {
                this.decrementServerCallCounter();
                // console.log(url, res);
                if (res.type == 'SUCCESS') {
                    observer.next(res);
                    observer.complete();
                } else {
                    this.resErrorHandling(res, observer);
                }
            }, (err) => {
                this.httpError(err);
            });
        });
    }

    genericPost(url, body, options): Observable<Response> {
        // console.log(url, body, options);
        this.incrementServerCallCounter();
        return new Observable((observer) => {
            this.http.post<Response>(environment.baseURL + url, body, options).subscribe((res: any) => {
                this.decrementServerCallCounter();
                console.log(url, res);
                if (res.type == 'SUCCESS') {
                    observer.next(res);
                    observer.complete();
                } else {
                    this.resErrorHandling(res, observer);
                }
            }, (err) => {
                this.httpError(err);
            });
        });
    }


    joinGame(gameCode, nickname, contact, imgUrl): Observable<Response> {
        const body = { gameCode: gameCode, nickname: nickname, contact: contact, imgUrl: imgUrl };
        return this.genericPost('/api/player/joinGame/', body, {});
    }

    createGame(body): Observable<Response> {
        return this.genericPost('/api/game/createGame/', body, {});
    }

    beginGame(): Observable<Response> {
        let headers = new HttpHeaders();
        headers = headers.append('playerID', this.storage.getItem('PlayerID'));
        const options = {
            headers: headers
        };
        return this.genericPost('/api/game/begin/', {}, options);
    }

    verifyPlayer(playerId, verifyCode): Observable<Response> {
        const body = 'verificationCode=' + verifyCode;
        let headers = new HttpHeaders();
        headers = headers.append('Content-Type', 'application/x-www-form-urlencoded');
        headers = headers.append('playerId', playerId);
        const options = {
            headers: headers
        };
        return this.genericPost('/api/player/verify/', body, options);
    }

    removeUnverifiedPlayer(removePlayerID): Observable<Response> {
        let headers = new HttpHeaders();
        headers = headers.append('Content-Type', 'application/x-www-form-urlencoded');
        const options = {
            headers: headers
        };
        const body = 'playerID=' + this.storage.getItem('PlayerID') + "&playerIDToRemove=" + removePlayerID;
        return this.genericPost('/api/player/remove/', body, options);
    }

    resendVerificationCode(playerId): Observable<Response> {
        let headers = new HttpHeaders();
        headers = headers.append('playerId', playerId);
        const options = {
            headers: headers
        };
        return this.genericPost('/api/player/resend/', {}, options);
    }

    getListOfPlayers(isPlayerID, filter, orderBy): Observable<Response> {
        return this.genericGet('/api/game/getAllPlayersInGame/' + this.storage.getItem('PlayerID') + '/' + isPlayerID + '/' + filter + '/' + orderBy, {});
    }

    getPlayerNotifications(getAll): Observable<Response> {
        return this.genericGet('/api/player/getNotifications/' + this.storage.getItem('PlayerID') + '/' + getAll, {});
    }

    getPlayerNotificationCount(): Observable<Response> {
        const options = {
            headers: new HttpHeaders({ 'playerID': this.storage.getItem('PlayerID') })
        };
        return this.genericGet('/api/player/unread/', options);
    }

    uploadPhoto(dataUrl, photoOfID, latitude, longitude): Observable<Response> {
        const body = {
            imgUrl: dataUrl,
            takenByID: this.storage.getItem('PlayerID'),
            photoOfID: photoOfID,
            latitude: latitude,
            longitude: longitude
        }
        return this.genericPost('/api/photo/upload/', body, {});
    }

    getVotablePhotos(): Observable<Response> {
        const options = {
            headers: new HttpHeaders({ 'playerId': this.storage.getItem('PlayerID') })
        };
        return this.genericGet('/api/photo/vote/', options);
    }

    sendPhotoVote(voteID, decision): Observable<Response> {
        const body = 'decision=' + decision;
        let headers = new HttpHeaders();
        headers = headers.append('Content-Type', 'application/x-www-form-urlencoded');
        headers = headers.append('playerId', this.storage.getItem('PlayerID'));
        headers = headers.append('voteId', voteID);
        const options = {
            headers: headers
        };
        return this.genericPost('/api/photo/vote/', body, options);
    }

    postLeaveGame(): Observable<Response> {
        let headers = new HttpHeaders();
        headers = headers.append('playerID', this.storage.getItem('PlayerID'));
        const options = {
            headers: headers
        };
        return this.genericPost('/api/player/leaveGame/', '', options);
    }

    unverifiedLeaveGame(playerID): Observable<Response> {
        let headers = new HttpHeaders();
        headers = headers.append('playerID', playerID);
        const options = {
            headers: headers
        };
        return this.genericPost('/api/player/leaveGame/', '', options);
    }

    postReadNotifications(notificationArray): Observable<Response> {
        const body = {
            playerID: this.storage.getItem('PlayerID'),
            notificationArray: notificationArray
        }
        return this.genericPost('/api/player/setNotificationsRead/', body, {});
    }

    getGameStatus(): Observable<Response> {
        const options = {
            headers: new HttpHeaders({ 'playerId': this.storage.getItem('PlayerID') })
        };
        return this.genericGet('/api/game/status/', options);
    }

    getPlayerAmmoCount(): Observable<Response> {
        const options = {
            headers: new HttpHeaders({ 'playerId': this.storage.getItem('PlayerID') })
        };
        return this.genericGet('/api/player/ammo/', options);
    }

    getLastKnownLocations(): Observable<Response> {
        let headers = new HttpHeaders();
        headers = headers.append('playerID', this.storage.getItem('PlayerID'));
        const options = {
            headers: headers
        };
        return this.genericGet('/api/map/', options);
    }

    consumeAmmo(latitude, longitude): Observable<Response> {
        let headers = new HttpHeaders();
        headers = headers.append('Content-Type', 'application/x-www-form-urlencoded');
        headers = headers.append('playerID', this.storage.getItem('PlayerID'));
        const body = 'latitude=' + latitude + '&longitude=' + longitude;
        const options = {
            headers: headers
        };
        return this.genericPost('/api/player/useAmmo/', body, options);
    }

    // Handles any code errors that the server might return. If the error code matches one of these global ones, it will handle it accordingly.
    resErrorHandling(res, observer) {
        switch (res.errorCode) {
            case 10:
                console.log('Player does not exist');
                this.storage.clearEverything();
                this.router.navigateByUrl('/start');
                break;
            case 16:
                console.log('Game is finished');
                this.router.navigateByUrl('/scoreboard');
                break;
            case 111:
                console.log('Player does not exist');
                this.storage.clearEverything();
                this.router.navigateByUrl('/start');
                break;
        }
        observer.error(res);
    }

    // Handles any generic HTTP errors.
    httpError(err) {
        console.log(err);
        this.decrementServerCallCounter();
        this.errorService.throwError('Unable to contact server', 'We cannot contact our servers at this time. Please check your internet connection, and try again.')
    }
}
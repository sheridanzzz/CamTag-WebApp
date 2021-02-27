/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: The tag component displays the photo just taken, and allows you to select from the list of valid players who can be tagged.
*/

import { Component, OnInit, EventEmitter, Output } from '@angular/core';
import { ApiService } from '../../core/api.service';
import { StorageService } from '../../core/storage.service';
import { finalize } from 'rxjs/operators';
import { MessageService } from 'src/app/core/message.service';

@Component({
    selector: 'tag-page',
    templateUrl: './tag.component.html',
    styleUrls: ['./tag.component.css']
})
export class TagComponent implements OnInit {
    @Output() close: EventEmitter<any> = new EventEmitter<any>();
    picture: string;
    playerId: string;
    uploading = false;
    loadingPlayers = true;
    players: Array<any>;
    selectedPlayer = null;
    latitude = '';
    longitude = '';

    constructor(private api: ApiService, private storage: StorageService, private messageService: MessageService) { }

    ngOnInit() {
        this.picture = this.storage.getMemoryStorage('picture');
        this.latitude = this.storage.getMemoryStorage('latitude');
        this.longitude = this.storage.getMemoryStorage('longitude');
        this.playerId = this.storage.getItem('PlayerID');
        this.api.getListOfPlayers(true, 'Taggable', 'AZ')
            .pipe(finalize(() => {
                this.loadingPlayers = false;
            }))
            .subscribe(res => {
                this.players = res.data.players;
                console.log(this.players);
            }, error => {
                console.log(error);
            });
    }

    sendTag() {
        if (this.selectedPlayer) {
            this.uploading = true;
            console.log(this.picture, this.selectedPlayer.playerID);
            this.api.uploadPhoto(this.picture, this.selectedPlayer.playerID, this.latitude, this.longitude)
                .subscribe(res => {
                    console.log(res);
                    this.uploading = false;
                    this.closeModal();
                }, (err) => {
                    this.messageService.pushMessage('Issue Uploading Photo', err.errorMessage);
                    this.uploading = false;
                });
        }
    }

    closeModal() {
        this.close.emit();
    }
}
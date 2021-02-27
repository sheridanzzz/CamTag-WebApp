/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: Handles the voting modal for whenever a player needs to vote throughout the game.
*/

import { Component, OnInit, OnDestroy, Output, EventEmitter } from '@angular/core';
import { ApiService } from '../core/api.service';
import { PushService } from '../core/push.service';
import { Subscription } from 'rxjs';

@Component({
    selector: 'voting-page',
    templateUrl: './voting.component.html',
    styleUrls: ['./voting.component.css']
})
export class VotingComponent implements OnInit, OnDestroy {
    @Output() close: EventEmitter<any> = new EventEmitter<any>();
    selectedVote: any;
    photoVotes = [];
    private voteSub: Subscription;

    constructor(private api: ApiService, private pushService: PushService) { }

    ngOnInit() {
        this.getVotes();

        // Subscribes to the vote Subject so that if a new vote comes through while on the page, it is automatically updated.
        this.voteSub = this.pushService.photoVoteUpdate.subscribe((res) => {
            this.getVotes();
        });
    }

    ngOnDestroy() {
        this.voteSub.unsubscribe();
    }

    getVotes() {
        this.api.getVotablePhotos()
            .subscribe(res => {
                console.log(res.data);
                this.photoVotes = res.data;
                if (res.data.length > 0) {
                    this.selectedVote = this.photoVotes[0];
                } else {
                    this.close.emit();
                }
            });
    }

    // Sends the decided vote (yes/no) to the server along with the vote ID and the player who voted.
    vote(response) {
        this.api.sendPhotoVote(this.selectedVote.voteID, response)
            .subscribe(res => {
                this.photoVotes = this.photoVotes.slice(1);
                console.log(this.photoVotes);
                if (this.photoVotes.length > 0) {
                    this.selectedVote = this.photoVotes[0];
                } else {
                    this.close.emit();
                }
            }, error => {
                console.log('ERROR CALLBACK');
            });
    }
}
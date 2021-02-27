/*
This component was written for the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: Is the starting point for the app. Every other page is displayed through this, and it holds and global modals such as voting or the help page.
*/

/*
Program Summary:
This Angular app provides the frontend for the Camtag application. It is written in Angular 6. It interacts with the backend via
REST APIs. The API URLs can be tweaked in the environments folder.

How to run (dev environment):
1. Ensure you have Node.js installed.
2. Open a command prompt in the main folder (where the angular and package files exist)
3. run 'npm install @angular/cli'
4. run 'npm install'
5. run 'npm start'

Program Structure:
Most of the program lives in the src/app folder. Within this folder, there are three main parts: The app stuff, the core folder, and the other folders.
The app files are the base of the app. Everything else runs from these. The app-routing module handles all routing for the application. 
The core folder handles any services that are may exist throughout the lifetime of the program. They are only instantiated once. All other folders and files are regular components.
They may be used and discarded as needed throughout the lifetime of the program. The main folder only refers to the primary page used in the app,
not the main class program-wise.
*/

import { Component, HostListener, OnDestroy } from '@angular/core';
import { Router, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs/operators';
import { StorageService } from './core/storage.service';
import { PushService } from './core/push.service';
import { ApiService } from './core/api.service';
import { Subscription } from 'rxjs';
import { MessageService } from './core/message.service';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent implements OnDestroy {

  @HostListener('document:visibilitychange', ['$event'])
  onVisibilityChange(event: any): void {
    console.log("Visibilitychange:", event);
    console.log(document.visibilityState);
    if (document.visibilityState == 'hidden') {
      this.pushService.disconnect();
    } else {
      this.pushService.connect();
    }
  }

  messageModalSub: Subscription;
  helpModalSub: Subscription;
  serverCallSub: Subscription;
  photoVoteUpdateSubscription: Subscription;
  playerEliminatedSub: Subscription;
  gameStartingSub: Subscription;
  gameNowPlayingSub: Subscription;
  gameCompletedSub: Subscription;
  playerDisabledSub: Subscription;
  playerReenabledSub: Subscription;
  showMessageModal = false;
  showHelpModal = false;
  showVotingModal = false;
  loading = false;
  isConnected = false;

  title = 'Cam Tag';
  playerID = this.storage.getItem('PlayerID');

  constructor(private router: Router, private storage: StorageService, private pushService: PushService, private api: ApiService, private messageService: MessageService) {
    router.events.pipe(filter(event => event instanceof NavigationEnd)).subscribe((val) => {
      // console.log('navigation finished:', val);
      this.playerID = this.storage.getItem('PlayerID');
    });

    if (this.storage.getItem("PlayerID")) {
      this.pushService.initialise();
    }

    this.messageModalSub = this.messageService.showMessageModal.subscribe((res) => {
      this.showMessageModal = true;
    });

    this.helpModalSub = this.messageService.showHelpModal.subscribe((res) => {
      this.showHelpModal = true;
    });

    this.photoVoteUpdateSubscription = this.pushService.photoVoteUpdate.subscribe((res) => {
      console.log('Trigger to vote');
      this.showVotingModal = true;
    });

    this.pushService.isConnectedTest.subscribe((res: boolean) => {
      this.isConnected = res;
    });

    this.gameStartingSub = this.pushService.gameStarting.subscribe((res) => {
      this.router.navigateByUrl("/lobby");
    });

    this.gameNowPlayingSub = this.pushService.gameNowPlaying.subscribe((res) => {
      this.router.navigateByUrl("/");
    });

    this.gameCompletedSub = this.pushService.gameCompleted.subscribe((res) => {
      this.storage.setItem("GameState", "COMPLETED");
      this.router.navigateByUrl("/scoreboard");
    });

    this.playerEliminatedSub = this.pushService.playerEliminated.subscribe((res) => {
      this.messageService.pushMessage("Elimination", "You have been eliminated.");
      this.storage.setItem("PlayerStatus", "ELIMINATED");
      this.router.navigateByUrl("/scoreboard");
    });

    // Set up player disabled subscription.
    this.playerDisabledSub = this.pushService.playerDisabled.subscribe((res) => {
      this.storage.setItem('PlayerStatus', 'DISABLED');
    });

    this.playerReenabledSub = this.pushService.playerReenabled.subscribe((res) => {
      this.storage.setItem('PlayerStatus', 'ACTIVE');
    });


    this.serverCallSub = this.api.waitingForServer.subscribe((res: boolean) => {
      this.loading = res;
    });
  }

  ngOnDestroy() {
    this.messageModalSub.unsubscribe();
    this.helpModalSub.unsubscribe();
    this.photoVoteUpdateSubscription.unsubscribe();
    this.playerEliminatedSub.unsubscribe();
    this.serverCallSub.unsubscribe();
    this.gameStartingSub.unsubscribe();
    this.gameNowPlayingSub.unsubscribe();
    this.gameCompletedSub.unsubscribe();
    this.playerDisabledSub.unsubscribe();
    this.playerReenabledSub.unsubscribe();
  }

  hideModal(event, id) {
    console.log('hide modal:', event, id);
    if (event != null && event.target.id == id) {
      switch (id) {
        case 'helpModal':
          this.showHelpModal = false;
          break;
      }
    }
  }
}
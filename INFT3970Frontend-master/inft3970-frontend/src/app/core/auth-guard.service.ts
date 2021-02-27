/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: Manages the authorisation for accessing pages in the app. If the app tries to access a page that it is 
not allowed to, the the auth guard will re-route it to the first page in the list that it is allowed to access.
*/

import { Injectable } from '@angular/core';
import { Router, CanActivate, ActivatedRouteSnapshot } from '@angular/router';
import { StorageService } from './storage.service';

@Injectable()
export class AuthGuard implements CanActivate {
  
  constructor(private router: Router, private storage: StorageService) { }
  
  canActivate(target: ActivatedRouteSnapshot) {
    return this.checkAuthorisedPage("/" + (target.url.length > 0 ? target.url[0] : ''));
  }

  checkAuthorisedPage(url) {
    let authorised = false;
    // List of pages that the app can access depending on the game mode
    const pageAuthorisations = {
      "IN LOBBY": ["/lobby", "/error"],
      "STARTING": ["/lobby", "/error"],
      "PLAYING": ["/", "/scoreboard", "/error"],
      "COMPLETED": ["/scoreboard", "/error"],
      "NOGAME": ["/start", "/join", "/create", "/error"]
    }

    let gameState = this.storage.getItem("GameState");
    let playerStatus = this.storage.getItem("PlayerStatus");
    
    // Custom state changes depending on other settings
    if (gameState == "" || gameState == null) {
      gameState = "NOGAME";
    }
    if (playerStatus == 'ELIMINATED'){
      gameState = 'COMPLETED';
    }
    
    pageAuthorisations[gameState].forEach(authorisedPage => {
      if (url == authorisedPage) {
        authorised = true;
      }
    });

    if (!authorised) {
      this.router.navigateByUrl(pageAuthorisations[gameState][0]);
    }
    return authorised;
  }
}
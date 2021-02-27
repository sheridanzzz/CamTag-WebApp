/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: Handles the setup and configuration of the various elements and components of the Summary folder.
*/

import { NgModule } from '@angular/core';

import { LobbyComponent } from './lobby/lobby.component';
import { ScoreboardComponent } from './scoreboard/scoreboard.component';
import { AppRoutingModule } from '../app-routing.module';
import { BrowserModule } from '@angular/platform-browser';

@NgModule({
    imports: [AppRoutingModule, BrowserModule],
    declarations: [LobbyComponent, ScoreboardComponent],
    providers: [],
    exports: []
})
export class SummaryModule {
}
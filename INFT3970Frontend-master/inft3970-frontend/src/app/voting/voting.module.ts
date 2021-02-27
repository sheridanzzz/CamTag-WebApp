/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: Handles the configuration for the vote page.
*/

import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { CommonModule } from '@angular/common';

import { AppRoutingModule } from '../app-routing.module';
import { VotingComponent } from './voting.component';

@NgModule({
    imports: [AppRoutingModule, BrowserModule, CommonModule],
    declarations: [VotingComponent],
    providers: [],
    exports: [VotingComponent]
})

export class VotingModule {
}
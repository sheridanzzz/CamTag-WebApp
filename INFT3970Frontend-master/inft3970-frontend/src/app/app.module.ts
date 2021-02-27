/*
This component was written for the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: The App Module is the core module that handles all other modules. It loads the app component,
and delegates setup and configuration to the other modules.
*/

import { NgModule } from '@angular/core';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { CoreModule } from './core/core.module';
import { MainModule } from './main/main.module';
import { SummaryModule } from './summary/summary.module';
import { StartModule } from './start/start.module';
import { VotingModule } from './voting/voting.module';
import { CommonModule } from '@angular/common';


@NgModule({
  declarations: [
    AppComponent
  ],
  imports: [
    CoreModule,
    CommonModule,
    VotingModule,
    MainModule,
    SummaryModule,
    StartModule,
    AppRoutingModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
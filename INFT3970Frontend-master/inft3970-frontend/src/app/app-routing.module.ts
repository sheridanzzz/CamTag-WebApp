/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: Handles all of the routing configuration for the app. Will also call the AuthGuard to check whether the player should be
accessing a certain page at the point in the game.
*/

import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';

import { AuthGuard } from './core/auth-guard.service';
import { PageNotFoundComponent } from './shared/not-found.component';
import { MainComponent } from './main/main.component';
import { LobbyComponent } from './summary/lobby/lobby.component';
import { ScoreboardComponent } from './summary/scoreboard/scoreboard.component';
import { StartComponent } from './start/start.component';
import { JoinComponent } from './start/join/join.component';
import { CreateComponent } from './start/create/create.component';
import { SharedModule } from './shared/shared.module';
import { ErrorComponent } from './core/error/error.component';

const appRoutes: Routes = [
    { path: '', component: MainComponent, canActivate: [AuthGuard] },
    { path: 'error', component: ErrorComponent, canActivate: [AuthGuard] },
    { path: 'start', component: StartComponent, canActivate: [AuthGuard] },
    { path: 'join', component: JoinComponent, canActivate: [AuthGuard] },
    { path: 'create', component: CreateComponent, canActivate: [AuthGuard] },
    { path: 'lobby', component: LobbyComponent, canActivate: [AuthGuard] },
    { path: 'scoreboard', component: ScoreboardComponent, canActivate: [AuthGuard] },
    { path: '**', component: PageNotFoundComponent }
];

@NgModule({
    imports: [
        SharedModule,
        RouterModule.forRoot(appRoutes)
    ],
    exports: [
        RouterModule
    ]
})
export class AppRoutingModule { }
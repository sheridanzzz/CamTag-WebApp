/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.
*/

import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';

import { MainComponent } from './main.component';
import { AppRoutingModule } from '../app-routing.module';
import { TagComponent } from './tag/tag.component';
import { MapsComponent } from './map/maps.component';
import { NotificationsComponent } from './notifications/notifications.component';
import { VotingModule } from '../voting/voting.module';

@NgModule({
    imports: [AppRoutingModule, FormsModule, CommonModule, VotingModule],
    declarations: [MainComponent, TagComponent, MapsComponent, NotificationsComponent],
    providers: [],
    exports: []
})
export class MainModule {
}
/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: Handles the setup and configuration of the various elements and components in the Start folder.
*/

import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';  

import { AppRoutingModule } from '../app-routing.module';
import { StartComponent } from './start.component';
import { JoinComponent } from './join/join.component';
import { CreateComponent } from './create/create.component';
import { SelfieComponent } from './selfie/selfie.component';
import { VerificationComponent } from './verification/verification.component';
import { SettingsComponent } from './settings/settings.component';
import { SettingsMapComponent } from './settings/settings-map/settings-map.component';

@NgModule({
    imports: [
        AppRoutingModule,
        FormsModule,
        CommonModule
    ],
    declarations: [
        StartComponent,
        JoinComponent,
        CreateComponent,
        SelfieComponent,
        SettingsComponent,
        SettingsMapComponent,
        VerificationComponent
    ],
    providers: [],
    exports: []
})
export class StartModule { }
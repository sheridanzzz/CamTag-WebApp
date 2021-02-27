/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: The core module handles the setup and management of all the various services and components in the Core folder.
*/

import { NgModule, Optional, SkipSelf } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { HttpClientModule } from '@angular/common/http';
import { FormsModule } from '@angular/forms';

import { AuthGuard } from './auth-guard.service';
import { ApiService } from './api.service';
import { throwIfAlreadyLoaded } from './module-import-guard';

import { AppRoutingModule } from '../app-routing.module';
import { StorageService } from './storage.service';
import { PushService } from './push.service';
import { LocationService } from './location.service';
import { SharedModule } from '../shared/shared.module';
import { ErrorService } from './error.service';
import { MessageComponent } from './message/message.component';
import { ErrorComponent } from './error/error.component';
import { MessageService } from './message.service';

@NgModule({
    imports: [
        AppRoutingModule,
        BrowserModule,
        HttpClientModule,
        FormsModule,
        SharedModule
    ],
    declarations: [MessageComponent, ErrorComponent],
    providers: [AuthGuard, ApiService, StorageService, PushService, LocationService, ErrorService, MessageService],
    exports: [MessageComponent]
})
export class CoreModule {
    constructor(@Optional() @SkipSelf() parentModule: CoreModule) {
        throwIfAlreadyLoaded(parentModule, 'CoreModule');
    }
}
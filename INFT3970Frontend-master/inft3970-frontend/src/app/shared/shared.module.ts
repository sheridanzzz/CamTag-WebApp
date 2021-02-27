/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: The Shared module sets up any components that can be instantiated as many times as needed (compared to the Core components, which are only 
    set up once in the life of the app).
*/

import { NgModule } from '@angular/core';

import { PageNotFoundComponent } from './not-found.component';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';

@NgModule({
    imports: [
        CommonModule,
        FormsModule,
        RouterModule
    ],
    declarations: [
        PageNotFoundComponent

    ],
    providers: [PageNotFoundComponent],
    exports: [
    ]
})
export class SharedModule { }